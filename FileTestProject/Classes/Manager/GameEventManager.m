//
//  GameEventManager.m
//  FileTestProject
//
//  Created by Yujie Liu on 10/31/16.
//  Copyright © 2016 Yujie Liu. All rights reserved.
//

#import "GameEventManager.h"
#import "DataManager.h"
#import "BaseButtonGroup.h"
#import "CityScene.h"
#import "GamePanelManager.h"
#import "GameConditionManager.h"
#import "GameDataManager.h"
#import "BGImage.h"
#import "GameValueManager.h"
#import "GameTimerManager.h"
#import "BaseScene.h"
#import "MenuPage.h"
#import "GameCityData.h"
#import "CityTaskButtonGroup.h"

static GameEventManager *_sharedEventManager;

@implementation GameEventManager
{
    NSDictionary *_eventDictionary;
    NSMutableArray *_viewStack;
    NSArray *_eventList;
    NSInteger _currentEventIndex;
    NSArray *_dialogList;
    NSInteger _currentDialogIndex;
    NSInteger _currentDays;
    NSInteger _totalDays;
    NSArray *_tempDialogContent;
    CCNode *_transCover;
    __weak DialogPanel *_dialog;
}

+ (GameEventManager *)sharedEventManager
{
    if (!_sharedEventManager) {
        _sharedEventManager = [[GameEventManager alloc] init];
    }
    return _sharedEventManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _eventDictionary = [[DataManager sharedDataManager].getEventActionDic getDictionary];
        _viewStack = [NSMutableArray new];
    }
    return self;
}

- (void)clear
{
    [_viewStack removeAllObjects];
    _eventList = nil;
    _currentEventIndex = 0;
    _dialogList = nil;
    _currentDialogIndex = 0;
    _tempDialogContent = nil;
}

- (CCNode *)topPanel;
{
    if (_viewStack.count > 0) {
        return [_viewStack lastObject];
    }
    return nil;
}

- (void)popPanel
{
    if (_viewStack.count > 0) {
        CCNode *node = [_viewStack lastObject];
        [_viewStack removeLastObject];
        [node removeFromParent];
    }
}

- (void)startEventId:(NSString *)eventId withScene:(CCScene *)scene
{
    EventActionData *eventData = [_eventDictionary objectForKey:eventId];
    NSLog(@"====================== %@", eventId);
    if (eventData) {
        if ([eventData.eventType isEqualToString:@"close"]) {
            [self popPanel];
            [self _startEventList];
        } else if ([eventData.eventType isEqualToString:@"checkStory"]) {
            if (_viewStack.count == 0 && [[CCDirector sharedDirector].runningScene isKindOfClass:[CityScene class]]) {
                CCScene *scene = [CCDirector sharedDirector].runningScene;
                [(CityScene *)scene checkStory:@"0"];
            }
            [self _startEventList];
        } else if ([eventData.eventType isEqualToString:@"selectlist"]) {
            BaseButtonGroup *buttonGroup = [[BaseButtonGroup alloc] initWithEventActionData:eventData];
            buttonGroup.baseScene = scene;
            [_viewStack addObject:buttonGroup];
            [scene addChild:buttonGroup];
        } else if ([eventData.eventType isEqualToString:@"dialog"]) {
            _dialogList = [eventData.parameter componentsSeparatedByString:@";"];
            _currentDialogIndex = 0;
            [self _startEventList];
        } else if ([eventData.eventType isEqualToString:@"eventList"]) {
            _eventList = [eventData.parameter componentsSeparatedByString:@";"];
            _currentEventIndex = 0;
            [self _startEventList];
        } else if ([eventData.eventType isEqualToString:@"window"]) {
            BasePanel *sprite = [BasePanel panelWithParameters:eventData.parameter];
            sprite.completionBlockWithEventId = ^(NSString *eventId) {
                [self startEventId:eventId withScene:scene];
            };
            [_viewStack addObject:sprite];
            [scene addChild:sprite];
        } else if ([eventData.eventType isEqualToString:@"condition"]) {
            NSArray *array = [eventData.parameter componentsSeparatedByString:@";"];
            if (array.count > 1) {
                if ([[GameConditionManager sharedConditionManager] checkCondition:array[0]]) {
                    _eventList = [array[1] componentsSeparatedByString:@"_"];
                    _currentEventIndex = 0;
                    [self _startEventList];
                } else if (array.count > 2) {
                    _eventList = [array[2] componentsSeparatedByString:@"_"];
                    _currentEventIndex = 0;
                    [self _startEventList];
                }
            }
        } else if ([eventData.eventType isEqualToString:@"wait"]) {
            _totalDays = [[GameValueManager sharedValueManager] getNumberByTerm:eventData.parameter];
            _currentDays = 0;
            [self _addTransparentCover];
            [self _waitADay];
        } else if ([eventData.eventType isEqualToString:@"setNumber"]) {
            [[GameValueManager sharedValueManager] setNumberByTerm:eventData.parameter];
            [self _startEventList];
        } else if ([eventData.eventType isEqualToString:@"setString"]) {
            [[GameValueManager sharedValueManager] setStringByTerm:eventData.parameter];
            [self _startEventList];
        } else if ([eventData.eventType isEqualToString:@"dialogTemp"]) {
            NSMutableArray *tempList = [[eventData.parameter componentsSeparatedByString:@";"] mutableCopy];
            for (NSInteger i = 0; i < tempList.count; ++i) {
                NSString *str = [[GameValueManager sharedValueManager] getStringByTerm:tempList[i]];
                if (!str || str.length == 0) {
                    str = [@([[GameValueManager sharedValueManager] getNumberByTerm:tempList[i]]) stringValue] ;
                }
                tempList[i] = str;
            }
            _tempDialogContent = tempList;
            [self _startEventList];
        } else if ([eventData.eventType isEqualToString:@"dialogYesNo"]) {
            NSArray *resultArr = [eventData.parameter componentsSeparatedByString:@";"];
            [self _setDialogWithId:resultArr[0]];
            [_dialog addYesNoWithCallback:^(int index) {
                [self startEventId:resultArr[index + 1] withScene:scene];
            }];
        } else if ([eventData.eventType isEqualToString:@"dataChange"]) {
            [[GameDataManager sharedGameData] dataChangeWithTerm:eventData.parameter];
            [self _startEventList];
        } else if ([eventData.eventType isEqualToString:@"scene"]) {
            BaseScene *baseScene = [BaseScene sceneWithParameters:eventData.parameter];
            [[CCDirector sharedDirector] pushScene:baseScene];
        } else if ([eventData.eventType isEqualToString:@"mainScene"]) {
            // 返回主界面
            [[CCDirector sharedDirector] presentScene:[[MenuPage alloc] init]];
            // 清除当前所有数据
            [GameDataManager clearCurrentGame];
        } else if ([eventData.eventType isEqualToString:@"cityTask"]) {
            // 当前城市任务
            GameCityData *cityData = [[GameDataManager sharedGameData].cityDic objectForKey:[GameDataManager sharedGameData].myGuild.myTeam.currentCityId];
            NSArray *taskList = [cityData cityTasks];
            CityTaskButtonGroup *buttonGroup = [[CityTaskButtonGroup alloc] initWithTasks:taskList];
            buttonGroup.baseScene = scene;
            if (eventData.parameter.length > 0 && ![eventData.parameter isEqualToString:@";"]) {
                buttonGroup.cancelEvent = eventData.parameter;
            }
            buttonGroup.completionBlockWithEventId = ^(NSString *eventId) {
                [self startEventId:eventId withScene:scene];
            };
            [_viewStack addObject:buttonGroup];
            [scene addChild:buttonGroup];
        }
    } else if (eventId.length == 0) {
        [self _startEventList];
    } else {
        _tempDialogContent = @[eventId];
        [self startEventId:@"NIY" withScene:scene];
    }
}

- (void)startEventId:(NSString *)eventId
{
    CCScene *scene = [CCDirector sharedDirector].runningScene;
    [self startEventId:eventId withScene:scene];
}

- (void)_addTransparentCover
{
    [CCDirector sharedDirector].runningScene.userInteractionEnabled = NO;
    if (!_transCover) {
        _transCover = [BGImage getTransparentBackground];
    } else if (_transCover.parent) {
        [self _removeTransparentCover];
    }
    [[CCDirector sharedDirector].runningScene addChild:_transCover];
    [_viewStack addObject:_transCover];
}

- (void)_removeTransparentCover
{
    [CCDirector sharedDirector].runningScene.userInteractionEnabled = YES;
    if (_transCover) {
        [_transCover removeFromParent];
        [_viewStack removeObject:_transCover];
    }
}

- (void)_waitADay
{
    if (_currentDays < _totalDays) {
        [[GameTimerManager sharedTimerManager] addBlock:^{
            _currentDays++;
            [[GameDataManager sharedGameData] spendOneDay];
            [self _waitADay];
        } withInterval:0.2];
    } else {
        [self _removeTransparentCover];
        [self _startEventList];
    }
}

- (void)_startEventList
{
    if (_currentDialogIndex < _dialogList.count) {
        [self _setDialogWithId:_dialogList[_currentDialogIndex++]];
        [_dialog addConfirmHandler:^{
            _tempDialogContent = nil;
            [self _startEventList];
        }];
    } else if (_currentEventIndex < _eventList.count) {
        [self startEventId:_eventList[_currentEventIndex++]];
    } else {
        _currentEventIndex = 0;
        _eventList = nil;
    }
}

- (void)_setDialogWithId:(NSString *)dialogId
{
    _dialog = [GamePanelManager sharedDialogPanelAboveSprite:nil];
    [_dialog setDefaultDialog:dialogId arguments:_tempDialogContent];
    CCScene *scene = [CCDirector sharedDirector].runningScene;
    if (_dialog.parent != scene) {
        [scene addChild:_dialog];
    }
}

@end
