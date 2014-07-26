#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

const float MaxPlayerAccel = 400.0f;
const float MaxPlayerSpeed = 200.0f;
const float BorderCollisionDamping = 0.6f;
const float RotationBlendFactor = 0.2f;
const float TurretRotationBlendFactor = 0.05f;

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
    
    float _playerAngle;
    float _lastAngle;
    
    CCSprite *_cannonSprite;
    CCSprite *_turretSprite;
    
    float _turretLastAngle;
    float _turretAngle;
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
        
        _cannonSprite = [CCSprite spriteWithFile:@"Cannon.png"];
        _cannonSprite.position = ccp(_winSize.width/2.0f, _winSize.height/2.0f);
        [self addChild:_cannonSprite];
        
        _turretSprite = [CCSprite spriteWithFile:@"Turret.png"];
        _turretSprite.position = ccp(_winSize.width/2.0f, _winSize.height/2.0f);
        [self addChild:_turretSprite];
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
    [self updateTurret:delta];
}

- (void)updatePlayer:(ccTime)dt
{
    _playerSpeedX += _playerAccelX * dt;
    _playerSpeedY += _playerAccelY * dt;
    
    _playerSpeedX = fmaxf(fminf(_playerSpeedX, MaxPlayerSpeed), -MaxPlayerSpeed);
    _playerSpeedY = fmaxf(fminf(_playerSpeedY, MaxPlayerSpeed), -MaxPlayerSpeed);
    
    float newX = _playerSprite.position.x + _playerSpeedX * dt;
    float newY = _playerSprite.position.y + _playerSpeedY * dt;
    
    //newX = MIN(_winSize.width, MAX(newX, 0));
    //newY = MIN(_winSize.height, MAX(newY, 0));
    
    BOOL collidedWithVerticalBorder = NO;
    BOOL collidedWithHorizontalBorder = NO;
    
    if(newX < 0.0f)
    {
        newX = 0.0f;
        collidedWithVerticalBorder = YES;
    }
    else if(newX > _winSize.width)
    {
        newX = _winSize.width;
        collidedWithVerticalBorder = YES;
    }
    
    if (newY < 0.0f) {
        newY = 0.0f;
        collidedWithHorizontalBorder = YES;
    }
    else if (newY > _winSize.height)
    {
        newY = _winSize.height;
        collidedWithHorizontalBorder = YES;
    }
    
    if (collidedWithVerticalBorder) {
        _playerAccelX = -_playerAccelX * BorderCollisionDamping;
        _playerSpeedX = -_playerSpeedX * BorderCollisionDamping;
        _playerAccelY = _playerAccelY * BorderCollisionDamping;
        _playerSpeedY = _playerSpeedY * BorderCollisionDamping;
    }
    
    if (collidedWithHorizontalBorder) {
        _playerAccelX = _playerAccelX * BorderCollisionDamping;
        _playerSpeedX = _playerSpeedX * BorderCollisionDamping;
        _playerAccelY = -_playerAccelY * BorderCollisionDamping;
        _playerSpeedY = -_playerSpeedY * BorderCollisionDamping;
    }
    
    _playerSprite.position = ccp(newX, newY);
    
    float speed = sqrtf(_playerSpeedX*_playerSpeedX + _playerSpeedY*_playerSpeedY);
    if (speed > 40.0f) {
        float angle = atan2f(_playerSpeedY, _playerSpeedX);
        
        //did the angle flip from +Pi to -Pi, or -Pi to +Pi
        if (_lastAngle < -3.0f && angle > 3.0f)
        {
            _playerAngle += M_PI * 2.0f;
        }
        else if (_lastAngle > 3.0f && angle < -3.0f)
        {
            _playerAngle -= M_PI * 2.0f;
        }
        _lastAngle = angle;
        _playerAngle = angle * RotationBlendFactor + _playerAngle * (1.0f - RotationBlendFactor);
    }
    _playerSprite.rotation = 90.0f - CC_RADIANS_TO_DEGREES(_playerAngle);
    
}

- (void)updateTurret:(ccTime)dt
{
    float deltaX = _playerSprite.position.x - _turretSprite.position.x;
    float deltaY = _playerSprite.position.y - _turretSprite.position.y;
    

    float angle = atan2f(deltaY, deltaX);
        
    //did the angle flip from +Pi to -Pi, or -Pi to +Pi
    if (_turretLastAngle < -3.0f && angle > 3.0f)
    {
        _turretAngle += M_PI * 2.0f;
    }
    else if (_turretLastAngle > 3.0f && angle < -3.0f)
    {
        _turretAngle -= M_PI * 2.0f;
    }
    _turretLastAngle = angle;
    _turretAngle = angle * TurretRotationBlendFactor + _turretAngle * (1.0f - TurretRotationBlendFactor);

    _turretSprite.rotation = 90.0f - CC_RADIANS_TO_DEGREES(_turretAngle);
}

@end