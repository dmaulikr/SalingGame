//
//  DuleScene.m
//  FileTestProject
//
//  Created by LIU YUJIE on 3/16/16.
//  Copyright © 2016 Yujie Liu. All rights reserved.
//

#import "DuelScene.h"
#import "GameDataManager.h"
#import "GameNPCData.h"
#import "CCSprite+Ext.h"
#import "RoleAnimation.h"

typedef enum : NSUInteger {
    StatusNone,
    StatusWalking,
    StatusFighting,
    StatusEnding,
    StatusStory,
} StatusType;

@interface DuelScene() <RoleAnimationProtocol>

@end

@implementation DuelScene
{
    CGSize _viewSize;
    CCSprite *_backSprite;
    RoleAnimation *_heroRole;
    RoleAnimation *_enemyRole;
    CCLabelTTF *_heroHP;
    CCLabelTTF *_enemyHP;
    GameNPCData *_heroData;
    GameNPCData *_enemyData;
    StatusType _currState;
    CGPoint _heroEndPoint;
    CGPoint _enemyEndPoint;
    CGPoint _heroStartPoint;
    CGPoint _enemyStartPoint;
    NSTimeInterval _time;
    NSTimeInterval _currTime;
    CCSprite *_duelDeckSprite;
    int _turnNum;
    RoleAnimation *_winnerRole;
    RoleAnimation *_loserRole;
}

-(instancetype)initWithRoleId:(NSString *)roleId1 roleId:(NSString *)roleId2
{
    if (self = [self init]) {
        _viewSize = [CCDirector sharedDirector].viewSize;
        _backSprite = [CCSprite spriteWithImageNamed:@"DuelBackground.png"];
        _backSprite.scale = _contentSize.height / _backSprite.contentSize.height;
        _backSprite.positionType = CCPositionTypeNormalized;
        _backSprite.position = ccp(0.5, 0.5);
        [self addChild:_backSprite z:1];
        CGFloat offx = (_viewSize.width - _backSprite.contentSize.width * _backSprite.scale) / 2;
        
        _duelDeckSprite = [CCSprite spriteWithImageNamed:@"duelDeck.png"];
        _duelDeckSprite.scale = _backSprite.scale;
        _duelDeckSprite.positionType = CCPositionTypeNormalized;
        CGFloat x = (_viewSize.width - _backSprite.contentSize.width * _backSprite.scale * 0.22) / 2 / _viewSize.width;
        _duelDeckSprite.position = ccp(x, 0.5);
        [self addChild:_duelDeckSprite];
        
        _enemyData = [[GameDataManager sharedGameData].npcDic objectForKey:roleId1];
        
        CCLabelTTF *labEnermyName = [CCLabelTTF labelWithString:_enemyData.fullName fontName:nil fontSize:12];
        labEnermyName.positionType = CCPositionTypeNormalized;
        labEnermyName.anchorPoint = ccp(0, 0);
        labEnermyName.position = ccp(0.05, 0.60);
        [_backSprite addChild:labEnermyName];
        
        CCTexture *enemyTexture = [CCTexture textureWithFile:_enemyData.portrait];
        CCSprite *enermyPhoto = [CCSprite spriteWithTexture:enemyTexture
                                                       rect:CGRectMake(_enemyData.npcData.portraitPosX, _enemyData.npcData.portraitPosY, 81, 96)];
        enermyPhoto.anchorPoint = ccp(0.5, 1);
        enermyPhoto.positionType = CCPositionTypePoints;
        enermyPhoto.position = ccp(offx + 74 * _backSprite.scale, 418 * _backSprite.scale);
        enermyPhoto.scale = _backSprite.scale;
        [self addChild:enermyPhoto];
        
        _enemyRole = [[RoleAnimation alloc] initWithRoleId:roleId1];
        _enemyRole.positionType = CCPositionTypeNormalized;
        _enemyRole.position = ccp(0, 0.5);
        _enemyRole.animationDelegate = self;
        _enemyRole.anchorPoint = ccp(0, 0.5);
        _enemyRole.flipX = YES;
        [_duelDeckSprite addChild:_enemyRole];
        _enemyEndPoint = CGPointMake(0.42, 0.5);
        _enemyStartPoint = _enemyRole.position;
        
        _enemyHP = [CCLabelTTF labelWithString:[@(_enemyData.currHp) stringValue] fontName:nil fontSize:14];
        _enemyHP.positionType = CCPositionTypePoints;
        _enemyHP.position = ccp(83, 240);
        [_backSprite addChild:_enemyHP];
        
        _heroData = [[GameDataManager sharedGameData].npcDic objectForKey:roleId2];
        CCLabelTTF *labHeroName = [CCLabelTTF labelWithString:_heroData.fullName fontName:nil fontSize:12];
        labHeroName.positionType = CCPositionTypeNormalized;
        labHeroName.anchorPoint = ccp(1, 0);
        labHeroName.position = ccp(0.72, 0.365);
        [_backSprite addChild:labHeroName];
        
        CCTexture *heroTexture = [CCTexture textureWithFile:_heroData.portrait];
        CCSprite *heroPhoto = [CCSprite spriteWithTexture:heroTexture
                                                     rect:CGRectMake(_heroData.npcData.portraitPosX, _heroData.npcData.portraitPosY, 81, 96)];
        heroPhoto.anchorPoint = ccp(0.5, 1);
        heroPhoto.positionType = CCPositionTypePoints;
        heroPhoto.position = ccp(offx + 424 * _backSprite.scale, 162 * _backSprite.scale);
        heroPhoto.scale = _backSprite.scale;
        [self addChild:heroPhoto];
        
        _heroRole = [[RoleAnimation alloc] initWithRoleId:roleId2];
        _heroRole.positionType = CCPositionTypeNormalized;
        _heroRole.position = ccp(1, 0.5);
        _heroRole.anchorPoint = ccp(0, 0.5);
        _heroRole.animationDelegate = self;
        [_duelDeckSprite addChild:_heroRole];
        _heroEndPoint = CGPointMake(0.48, 0.5);
        _heroStartPoint = _heroRole.position;
        
        _heroHP = [CCLabelTTF labelWithString:[@(_heroData.currHp) stringValue] fontName:nil fontSize:14];
        _heroHP.positionType = CCPositionTypePoints;
        _heroHP.position = ccp(403, 240);
        [_backSprite addChild:_heroHP];
        
        [self setCurrentState:StatusWalking];
        _winnerRole = nil;
        _loserRole = nil;
    }
    return self;
}

-(void)setCurrentState:(StatusType)type
{
    if (_currState != type) {
        _currState = type;
        if (_currState == StatusWalking) {
            _heroRole.action = ActionTypeWalking;
            _enemyRole.action = ActionTypeWalking;
            _time = 1.5f;
        } else if (_currState == StatusFighting) {
            _heroRole.loops = NO;
            _enemyRole.loops = NO;
            _turnNum = 0;
            [self duelTurn];
        } else if (_currState == StatusEnding) {
            // 结束了, 做一些动画，结束后 回上一层， 并传回胜利角色
            // TODO: 添加可能要增加的动画，并且移动
            DuelResult result;
            if ([_winnerRole isEqual:_heroRole]) {
                result = DuelResultWin;
            } else if ([_winnerRole isEqual:_enemyRole]) {
                result = DuelResultLose;
            } else {
                result = DuelResultStory;
            }
            [self.delegate duelEnds:result];
        }
    }
}

-(void)duelTurn
{
    // 根据两边的实力，决定本回合谁赢
    _turnNum++;
    // TODO: 暂时写成随机0,1,2 谁大谁赢，大2则暴击
    int enermyValue = arc4random() % 3;
    int heroValue = arc4random() %3;
    if (enermyValue > heroValue) {
        if (enermyValue > heroValue + 1) {
            _enemyRole.action = ActionTypeCriticalHitting;
            [self role:_heroData getDamage:11];
        } else {
            _enemyRole.action = ActionTypeHitting;
            [self role:_heroData getDamage:2];
        }
        _heroRole.action = ActionTypeWouding;
    } else if (enermyValue < heroValue) {
        if (enermyValue < heroValue - 1) {
            _heroRole.action = ActionTypeCriticalHitting;
            [self role:_enemyData getDamage:100];
        } else {
            _heroRole.action = ActionTypeHitting;
            [self role:_enemyData getDamage:80];
        }
        _enemyRole.action = ActionTypeWouding;
    } else {
        _heroRole.action = ActionTypeHitting;
        _enemyRole.action = ActionTypeHitting;
    }
    NSLog(@"turn : %d", _turnNum);
}

-(void)role:(GameNPCData *)role getDamage:(int)damage
{
    role.currHp -= damage;
    if (role.currHp < 0) {
        role.currHp = 0;
    }
    if (role == _heroData) {
        _heroHP.string = [@(_heroData.currHp) stringValue];
    } else if (role == _enemyData) {
        _enemyHP.string = [@(_enemyData.currHp) stringValue];
    }
    if (role.currHp == 0) {
        if (_heroData.currHp > 0) {
            _winnerRole = _heroRole;
            _loserRole = _enemyRole;
        } else {
            _winnerRole = _enemyRole;
            _loserRole = _heroRole;
        }
        [self setCurrentState:StatusEnding];
    }
}

-(void)animationEnds:(id)roleAnimation
{
    if (_currState == StatusFighting) {
        if (_heroRole.stopped && _enemyRole.stopped) {
            if (_winnerRole != nil) {
                // 游戏结束了
                [self setCurrentState:StatusEnding];
            } else {
                [self duelTurn];
            }
        }
    }
}

-(CGPoint)interPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint ratio:(CGFloat)ratio
{
    return ccp(startPoint.x + (endPoint.x - startPoint.x) * ratio, startPoint.y + (endPoint.y - startPoint.y) * ratio);
}

-(void)update:(CCTime)delta
{
    if (_currState == StatusWalking) {
        _currTime += delta;
        if (_currTime < _time) {
            CGFloat ratio = _currTime / _time;
            _heroRole.position = [self interPoint:_heroStartPoint endPoint:_heroEndPoint ratio:ratio];
            _enemyRole.position = [self interPoint:_enemyStartPoint endPoint:_enemyEndPoint ratio:ratio];
        } else {
            _heroRole.position = _heroEndPoint;
            _enemyRole.position = _enemyEndPoint;
            [self setCurrentState:StatusFighting];
        }
    } else if (_currState == StatusFighting) {
        
    }
}

@end
