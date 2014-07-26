#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

const float MaxPlayerAccel = 400.0f;
const float MaxPlayerSpeed = 200.0f;

@implementation HelloWorldLayer
{
    CGSize _winSize;
    CCSprite *_playerSprite;
    
    UIAccelerationValue _accelerometerX;
    UIAccelerationValue _accelerometerY;
    
    float _playerAccelX;
    float _playerAccelY;
    float _playerSpeedX;
    float _playerSpeedY;
}

+ (CCScene *)scene
{
    CCScene *scene = [CCScene node];
    HelloWorldLayer *layer = [HelloWorldLayer node];
    [scene addChild:layer];
    return scene;
}

- (id)init
{
    if ((self = [super initWithColor:ccc4(94, 63, 107, 255)]))
    {
        _winSize = [CCDirector sharedDirector].winSize;
        
        _playerSprite = [CCSprite spriteWithFile:@"Player.png"];
        _playerSprite.position = ccp(_winSize.width - 50.0f, 50.0f);
        [self addChild:_playerSprite];
        
        self.accelerometerEnabled = YES;
        
        [self scheduleUpdate];
    }
    return self;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer
        didAccelerate:(UIAcceleration *)acceleration
{
    const double FilteringFactor = 0.75;
    
    _accelerometerX = acceleration.x * FilteringFactor + _accelerometerX * (1.0 - FilteringFactor);
    _accelerometerY = acceleration.y * FilteringFactor + _accelerometerY * (1.0 - FilteringFactor);
    
    if(_accelerometerY > 0.05){
        _playerAccelX = -MaxPlayerAccel;
    }else if(_accelerometerY < -0.05){
        _playerAccelX = MaxPlayerAccel;
    }
    
    if(_accelerometerX < -0.05){
        _playerAccelY = -MaxPlayerAccel;
    }else if(_accelerometerX > 0.05){
        _playerAccelY = MaxPlayerAccel;
    }
}

- (void)update:(ccTime)delta
{
    [self updatePlayer:delta];
}

- (void)updatePlayer:(ccTime)dt
{
    _playerSpeedX += _playerAccelX * dt;
    _playerSpeedY += _playerAccelY * dt;
    
    _playerSpeedX = fmaxf(fminf(_playerSpeedX, MaxPlayerSpeed), -MaxPlayerSpeed);
    _playerSpeedY = fmaxf(fminf(_playerSpeedY, MaxPlayerSpeed), -MaxPlayerSpeed);
    
    float newX = _playerSprite.position.x + _playerSpeedX * dt;
    float newY = _playerSprite.position.y + _playerSpeedY * dt;
    
    newX = MIN(_winSize.width, MAX(newX, 0));
    newY = MIN(_winSize.height, MAX(newY, 0));
    
    _playerSprite.position = ccp(newX, newY);
}

@end