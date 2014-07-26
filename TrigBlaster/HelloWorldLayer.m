#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

const float MaxPlayerAccel = 400.0f;
const float MaxPlayerSpeed = 200.0f;
const float BorderCollisionDamping = 0.6f;
const float RotationBlendFactor = 0.2f;
const float TurretRotationBlendFactor = 0.05f;

const int MaxHP = 100;
const float HealthBarWidth = 40.0f;
const float HealthBarHeight = 4.0f;

const float CannonCollisionRadius = 20.0f;
const float PlayerCollisionRadius = 10.0f;
const float CannonCollisionDamping = 0.8f;
const float CannonCollisionSpeed = 200.0f;

const float Margin = 20.0f;
const float PlayerMissileSpeed = 300.0f;
const float CannonHitRadius = 25.0f;

const float OrbiterSpeed = 120.0f;
const float OrbiterRadius = 60.0f;
const float OrbiterCollisionRadius = 20.0f;

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
    
    int _playerHP;
    int _cannonHP;
    CCDrawNode *_playerHealthBar;
    CCDrawNode *_cannonHealthBar;
    
    float _playerSpin;
    
    CCSprite *_playerMissileSprite;
    CGPoint _touchLocation;
    CFTimeInterval _touchTime;
    
    CCSprite *_orbiterSprite;
    float _orbiterAngle;
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
        
        _playerHealthBar = [[CCDrawNode alloc] init];
        _playerHealthBar.contentSize = CGSizeMake(HealthBarWidth, HealthBarHeight);
        [self addChild:_playerHealthBar];
        
        _cannonHealthBar = [[CCDrawNode alloc] init];
        _cannonHealthBar.contentSize = CGSizeMake(HealthBarWidth, HealthBarHeight);
        [self addChild:_cannonHealthBar];
        
        _cannonHealthBar.position = ccp(
                                        _cannonSprite.position.x - HealthBarWidth/2.0f + 0.5f,
                                        _cannonSprite.position.y - _cannonSprite.contentSize.height/2.0f - 10.0f + 05.f);
        
        _playerHP = MaxHP;
        _cannonHP = MaxHP;
        
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"Collision.wav"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"Shoot.wav"];
        
        self.touchEnabled = YES;
        _playerMissileSprite = [CCSprite spriteWithFile:@"PlayerMissile.png"];
        _playerMissileSprite.visible = NO;
        [self addChild:_playerMissileSprite];
        
        _orbiterSprite = [CCSprite spriteWithFile:@"Asteroid.png"];
        _orbiterSprite.position = ccp(_winSize.width/2.0f, _winSize.height/2.0f);
        [self addChild:_orbiterSprite];
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
    [self updatePlayerMissile:delta];
    [self updateTurret:delta];
    
    [self drawHealthBar:_playerHealthBar hp:_playerHP];
    [self drawHealthBar:_cannonHealthBar hp:_cannonHP];
    
    [self checkCollisionOfPlayerWithCannon];
    
    [self updateOrbiter:delta];
    
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
    
    _playerHealthBar.position = ccp(
                                    _playerSprite.position.x - HealthBarWidth/2.0f + 0.5f,
                                    _playerSprite.position.y - _playerSprite.contentSize.height - 15.0f + 0.5f);
    
    _playerSprite.rotation += _playerSpin;
    if (_playerSpin > 0.0f) {
        _playerSpin -= 2.0f * 360.0f * dt;
        if(_playerSpin < 0.0f)
        {
            _playerSpin = 0.0f;
        }
    }
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

- (void)drawHealthBar:(CCDrawNode *)node hp:(int)hp
{
    [node clear];
    
    CGPoint verts[4];
    verts[0] = ccp(0.0f, 0.0f);
    verts[1] = ccp(0.0f, HealthBarHeight - 1.0f);
    verts[2] = ccp(HealthBarWidth - 1.0f, HealthBarHeight - 1.0f);
    verts[3] = ccp(HealthBarWidth - 1.0f, 0.0f);
    
    ccColor4F clearColor = ccc4f(0.0f, 0.0f, 0.0f, 0.0f);
    ccColor4F fillColor = ccc4f(113.0f/255.0f, 202.0f/255.0f, 53.0f/255.0f, 1.0f);
    ccColor4F borderColor = ccc4f(35.0f/255.0f, 28.0f/255.0f, 40.0f/255.0f, 1.0f);
    
    [node drawPolyWithVerts:verts count:4 fillColor:clearColor borderWidth:1.0f borderColor:borderColor];
    
    verts[0].x += 0.5f;
    verts[0].y += 0.5f;
    verts[1].x += 0.5f;
    verts[1].y -= 0.5f;
    verts[2].x = (HealthBarWidth - 2.0f)*hp/MaxHP + 0.5f;
    verts[2].y -= 0.5f;
    verts[3].x = verts[2].x;
    verts[3].y += 0.5f;
    
    [node drawPolyWithVerts:verts count:4 fillColor:fillColor borderWidth:0.0f borderColor:borderColor];
}

- (void)checkCollisionOfPlayerWithCannon
{
    float deltaX = _playerSprite.position.x - _turretSprite.position.x;
    float deltaY = _playerSprite.position.y - _turretSprite.position.y;
    
    float distance = sqrtf(deltaX*deltaX + deltaY*deltaY);
    
    if(distance <= CannonCollisionRadius + PlayerCollisionRadius)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:@"Collision.wav"];
        
        float angle = atan2f(deltaY, deltaX);
        
        _playerSpeedX = cosf(angle) * CannonCollisionSpeed;
        _playerSpeedY = sinf(angle) * CannonCollisionSpeed;
        _playerAccelX = 0.0f;
        _playerAccelY = 0.0f;
        
        _playerHP = MAX(0, _playerHP - 20);
        _cannonHP = MAX(0, _cannonHP - 5);
        
        _playerSpin = 180.0f * 2.5f;
    }
}


- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    _touchLocation = location;
    _touchTime = CACurrentMediaTime();
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (CACurrentMediaTime() - _touchTime < 0.3 && !_playerMissileSprite.visible) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
        CGPoint diff = ccpSub(location, _touchLocation);
        if (ccpLength(diff) > 4.0f) {
            float angle = atan2f(diff.y, diff.x);
            _playerMissileSprite.rotation = 90.0f - CC_RADIANS_TO_DEGREES(angle);
            
            _playerMissileSprite.position = _playerSprite.position;
            _playerMissileSprite.visible = YES;
            
            float adjacent, opposite;
            CGPoint destination;
            
            //1
            if (angle <= -M_PI_4 && angle > -3.0f * M_PI_4)
            {
                // Shoot down
                angle = M_PI_2 - angle;
                adjacent = _playerMissileSprite.position.y + Margin;
                opposite = tanf(angle) * adjacent;
                destination = ccp(_playerMissileSprite.position.x - opposite, -Margin);
            }
            else if (angle > M_PI_4 && angle <= 3.0f * M_PI_4)
            {
                // Shoot up
                angle = M_PI_2 - angle;
                adjacent = _winSize.height - _playerMissileSprite.position.y + Margin;
                opposite = tanf(angle) * adjacent;
                destination = ccp(_playerMissileSprite.position.x + opposite, _winSize.height + Margin);
            }
            else if (angle <= M_PI_4 && angle > -M_PI_4)
            {
                // Shoot right
                adjacent = _winSize.width - _playerMissileSprite.position.x + Margin;
                opposite = tanf(angle) * adjacent;
                destination = ccp(_winSize.width + Margin, _playerMissileSprite.position.y + opposite);
            }
            else  // angle > 3.0f * M_PI_4 || angle <= -3.0f * M_PI_4
            {
                // Shoot left	
                adjacent = _playerMissileSprite.position.x + Margin;
                opposite = tanf(angle) * adjacent;
                destination = ccp(-Margin, _playerMissileSprite.position.y - opposite);
            }
            
            
            //2
            float hypotenuse = sqrtf(adjacent*adjacent + opposite*opposite);
            ccTime duration = hypotenuse / PlayerMissileSpeed;
            
            id action = [CCSequence actions:
                         [CCMoveTo actionWithDuration:duration position:destination],
                         [CCCallBlock actionWithBlock:^{
                _playerMissileSprite.visible = NO;
            }],nil];
            
            [_playerMissileSprite runAction:action];
            [[SimpleAudioEngine sharedEngine] playEffect:@"Shoot.way"];
        }
    }
}

- (void)updatePlayerMissile:(ccTime)dt
{
    if (_playerMissileSprite.visible) {
        float deltaX = _playerMissileSprite.position.x - _turretSprite.position.x;
        float deltaY = _playerMissileSprite.position.y - _turretSprite.position.y;
        
        float distance = sqrtf(deltaX*deltaX + deltaY*deltaY);
        if (distance < CannonHitRadius) {
            [[SimpleAudioEngine sharedEngine] playEffect:@"Hit.wav"];
            _cannonHP = MAX(0, _cannonHP - 10);
            
            _playerMissileSprite.visible = NO;
            [_playerMissileSprite stopAllActions];
        }
    }
}

- (void)updateOrbiter:(ccTime)dt
{
    //1
    _orbiterAngle += OrbiterSpeed * dt;
    _orbiterAngle = fmodf(_orbiterAngle, 360.0f);
    
    //2
    float x = cosf(CC_DEGREES_TO_RADIANS(_orbiterAngle)) * OrbiterRadius;
    float y = sinf(CC_DEGREES_TO_RADIANS(_orbiterAngle)) * OrbiterRadius;
    
    //3
    _orbiterSprite.position = ccp(_cannonSprite.position.x + x, _cannonSprite.position.y + y);
    
    _orbiterSprite.rotation = -_orbiterAngle;
    
    if (_playerMissileSprite.visible) {
        float deltaX = _playerMissileSprite.position.x - _orbiterSprite.position.x;
        float deltaY = _playerMissileSprite.position.y - _orbiterSprite.position.y;
        
        float distance = sqrtf(deltaX*deltaX + deltaY*deltaY);
        if (distance < OrbiterCollisionRadius) {
            _playerMissileSprite.visible = NO;
            [_playerMissileSprite stopAllActions];
            
            _orbiterSprite.scale = 2.0f;
            [_orbiterSprite runAction:[CCScaleTo actionWithDuration:0.5f scale:1.0f]];
        }
    }
}

@end