/*
 * ofxIOSDeviceMotion.mm
 *
 * Copyright 2013 (c) Matthew Gingold (gameover)
 * http://gingold.com.au http://vimeo.com/channels/gingold
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * If you're using this software for something cool consider sending
 * me an email to let me know about your project: m@gingold.com.au
 *
 */

#include "ofxIOSDeviceMotion.h"

@interface _ofxIOSDeviceMotion : CMMotionManager{}

@property (nonatomic, readonly ) ofxIOSDeviceMotion * parent;
@property (nonatomic, readwrite) float rate;

@property (nonatomic, readwrite ) BOOL bVerbose;
@property (nonatomic, readwrite ) BOOL bIsDataNew;
@property (nonatomic, strong, readwrite) CMAttitude* refAttitude;
@property (nonatomic, strong, readwrite) NSString* status;
@property (nonatomic, readwrite) BOOL bUseDeviceMotion;
@property (nonatomic, readwrite) BOOL bUseAccelerometer;
@property (nonatomic, readwrite) BOOL bUseGyroscope;
@property (nonatomic, readwrite) BOOL bUseMagnetometer;

- (void) start;
- (void) stop;
- (void) calibrate;

@end

@implementation _ofxIOSDeviceMotion
@synthesize bVerbose;
@synthesize status;
@synthesize rate;
@synthesize parent;
@synthesize bIsDataNew;
@synthesize refAttitude;
@synthesize bUseDeviceMotion;
@synthesize bUseAccelerometer;
@synthesize bUseGyroscope;
@synthesize bUseMagnetometer;

- (id) setup:(ofxIOSDeviceMotion*) _parent
{
    // init the obj-c class
    if(self.init){
        parent = _parent;
        return self;
    }
    
    return nil;

}

- (void) start
{
    refAttitude = nil;
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    if(self.deviceMotionAvailable && bUseDeviceMotion){
        NSLog(@"Using Device Motion updates");
        
        //johnty note: CMAttitudeReferenceFrameXArbitraryCorrectedZVertical ... works with iPhones (with magnetometers only! use the first line if using iTouch devices!
        
      [self startDeviceMotionUpdatesToQueue:queue withHandler:
//        [self startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical toQueue:[NSOperationQueue currentQueue] withHandler:
         ^(CMDeviceMotion *motionData, NSError *error){
             if (error) {
                 [self stopDeviceMotionUpdates];
                 NSLog(@"Device Motion encountered error: %@", error);
             } else {
                 
                 // store a reference attitude on start
                 if (refAttitude == nil) [self calibrate];
                 
                 // accelerometer (equivalent to CMAccelerometerData ie., includes gravity)
                 ofPoint & acceleration = self.parent->getAcceleration();
                 acceleration.x = motionData.userAcceleration.x + motionData.gravity.x;
                 acceleration.y = motionData.userAcceleration.y + motionData.gravity.y;
                 acceleration.z = motionData.userAcceleration.z + motionData.gravity.z;
                 
                 // gyro (equivalent to CMGyroData)
                 ofPoint & rotation = self.parent->getRotation();
                 rotation.x = motionData.rotationRate.x;
                 rotation.y = motionData.rotationRate.y;
                 rotation.z = motionData.rotationRate.z;
                 
                 // accelerometer WITHOUT gravity
                 ofPoint & uacceleration = self.parent->getAccelerationWithoutGravity();
                 uacceleration.x = motionData.userAcceleration.x;
                 uacceleration.y = motionData.userAcceleration.y;
                 uacceleration.z = motionData.userAcceleration.z;
                 
                 // EXPERIMENTAL: manual high-pass filter for instantaneous motion,
                 // from: http://disanji.net/iOS_Doc/#documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/MotionEvents/MotionEvents.html
                 
                 float kFilteringFactorInstant = 0.1f;
                 
                 ofPoint & iaccelaration = self.parent->getAccelerationInstaneous();
                 iaccelaration.x = uacceleration.x - ( (uacceleration.x * kFilteringFactorInstant) + (iaccelaration.x * (1.0 - kFilteringFactorInstant)) );
                 iaccelaration.y = uacceleration.y - ( (uacceleration.y * kFilteringFactorInstant) + (iaccelaration.y * (1.0 - kFilteringFactorInstant)) );
                 iaccelaration.z = uacceleration.z - ( (uacceleration.z * kFilteringFactorInstant) + (iaccelaration.z * (1.0 - kFilteringFactorInstant)) );
                 
                 // gravity vector
                 ofPoint & gravity = self.parent->getGravity();
                 gravity.x = motionData.gravity.x;
                 gravity.y = motionData.gravity.y;
                 gravity.z = motionData.gravity.z;
                 
                 // normalise attitude using initial reference
                 [motionData.attitude multiplyByInverseOfAttitude:refAttitude];
                 
                 // attitude (pitch, roll, yaw)
                 ofPoint & attitude = self.parent->getAttitude();
                 attitude.x = motionData.attitude.pitch;
                 attitude.y = motionData.attitude.roll;
                 attitude.z = motionData.attitude.yaw;
                 
                 // magnetometer
                 ofPoint & magnet = self.parent->getMagnetometer();
                 magnet.x = motionData.magneticField.field.x;
                 magnet.y = motionData.magneticField.field.y;
                 magnet.z = motionData.magneticField.field.z;
                 
                 self.parent->bIsDataNew = true;
                 self.parent->getTimeStampMillis() = ofGetElapsedTimeMillis();
             }
         }];
        
    }else{
        
        // individual accel, gyro, magnetic updates

        // accelerometer updates
        if(bUseAccelerometer){
            NSLog(@"Using Accelerometer updates");
            if(self.accelerometerAvailable){
                [self startAccelerometerUpdatesToQueue:queue withHandler:
                 ^(CMAccelerometerData *accelerometerData, NSError *error){
                     if (error) {
                         [self stopAccelerometerUpdates];
                         NSLog(@"Accelerometer encountered error: %@", error);
                     }else{
                         
                         ofPoint & acceleration = self.parent->getAcceleration();
                         acceleration.x = accelerometerData.acceleration.x;
                         acceleration.y = accelerometerData.acceleration.y;
                         acceleration.z = accelerometerData.acceleration.z;
                         
                         // EXPERIMENTAL: manual low- and high-pass filter for gravity/instantaneous motion,
                         // from: http://disanji.net/iOS_Doc/#documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/MotionEvents/MotionEvents.html
                         
                         float kFilteringFactorGravity = 0.1f;
                         float kFilteringFactorInstant = 0.1f;
                         
                         ofPoint & uaccelaration = self.parent->getAccelerationWithoutGravity();
                         uaccelaration.x = (acceleration.x * kFilteringFactorGravity) + (uaccelaration.x * (1.0 - kFilteringFactorGravity));
                         uaccelaration.y = (acceleration.y * kFilteringFactorGravity) + (uaccelaration.y * (1.0 - kFilteringFactorGravity));
                         uaccelaration.z = (acceleration.z * kFilteringFactorGravity) + (uaccelaration.z * (1.0 - kFilteringFactorGravity));
                         
                         ofPoint & iaccelaration = self.parent->getAccelerationInstaneous();
                         iaccelaration.x = acceleration.x - ( (acceleration.x * kFilteringFactorInstant) + (iaccelaration.x * (1.0 - kFilteringFactorInstant)) );
                         iaccelaration.y = acceleration.y - ( (acceleration.y * kFilteringFactorInstant) + (iaccelaration.y * (1.0 - kFilteringFactorInstant)) );
                         iaccelaration.z = acceleration.z - ( (acceleration.z * kFilteringFactorInstant) + (iaccelaration.z * (1.0 - kFilteringFactorInstant)) );
                         
                         self.parent->bIsDataNew = true; // buggy?
                         self.parent->getTimeStampMillis() = ofGetElapsedTimeMillis();
                         
                     }
                 }];
            }else{ // if(self.accelerometerAvailable){
                NSLog(@"This device has no accelerometer");
                bUseAccelerometer = false;
            }
        } // if(bUseAccelerometer){
        
        // gyroscope updates
        if(bUseGyroscope){
            NSLog(@"Using Gyro updates");
            if(self.gyroAvailable){
                [self startGyroUpdatesToQueue:queue withHandler:
                 ^(CMGyroData *gyroData, NSError *error) {
                     if(error){
                         [self stopGyroUpdates];
                         NSLog(@"Gyroscope encountered error: %@", error);
                     }else{
                         
                         ofPoint & rotation = self.parent->getRotation();
                         
                         rotation.x = gyroData.rotationRate.x;
                         rotation.y = gyroData.rotationRate.y;
                         rotation.z = gyroData.rotationRate.z;
                         self.parent->bIsDataNew = true; // buggy?
                         if(!bUseAccelerometer) self.parent->getTimeStampMillis() = ofGetElapsedTimeMillis();
                         
                     }
                 }];
            }else{ // if(self.gyroAvailable){
                NSLog(@"This device has no gyroscope");
                bUseGyroscope = false;
            }
        } // if(bUseGyroscope){
        
        // magnetometer updates
        if(bUseMagnetometer){
            if(self.magnetometerAvailable){
                NSLog(@"Using Magnetometer updates");
                [self startMagnetometerUpdatesToQueue:queue withHandler:
                 ^(CMMagnetometerData *magnetData, NSError *error) {
                     if(error){
                         [self stopMagnetometerUpdates];
                         NSLog(@"Magnetometer encountered error: %@", error);
                     }else{
                         
                         ofPoint & magnet = self.parent->getMagnetometer();
                         
                         magnet.x = magnetData.magneticField.x;
                         magnet.y = magnetData.magneticField.y;
                         magnet.z = magnetData.magneticField.z;
                         self.parent->bIsDataNew = true; // buggy?
                         if(!bUseAccelerometer && !bUseGyroscope) self.parent->getTimeStampMillis() = ofGetElapsedTimeMillis();
                         
                     }
                 }];
            }else{ // if(self.magnetometerAvailable){
                NSLog(@"This device has no magnetometer");
                bUseMagnetometer = false;
            }
        } // if(bUseMagnetometer){
        
    }
}

- (void) stop
{
    // stop motion sensors
    if(self.deviceMotionActive){
        [self stopDeviceMotionUpdates];
    }else{
        
        if(self.accelerometerActive){
            [self stopAccelerometerUpdates];
        }
        
        if(self.gyroActive){
            [self stopGyroUpdates];
        }
        
        if(self.magnetometerActive){
            [self stopGyroUpdates];
        }
        
    }
}

- (void) calibrate
{
    if(self.deviceMotionActive) refAttitude = [self.deviceMotion.attitude retain];
}

@end

//--------------------------------------------------------------
ofxIOSDeviceMotion::ofxIOSDeviceMotion(){
    
    // init the obj-c class
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    motion = [[_ofxIOSDeviceMotion alloc] setup:this];
    [pool release];
    
    // set default sample rate
    setSampleRate(60.0f);
    bIsDataNew = false;
    
    // set default sensors
    motion.bUseDeviceMotion = true;
    motion.bUseAccelerometer = true;
    motion.bUseGyroscope = true;
    motion.bUseMagnetometer = false;
}

//--------------------------------------------------------------
ofxIOSDeviceMotion::~ofxIOSDeviceMotion(){
    [motion stop];
}

////--------------------------------------------------------------
//void ofxIOSDeviceMotion::setup(){
//
//}

//--------------------------------------------------------------
void ofxIOSDeviceMotion::start(){
    bIsDataNew = false;
    [motion start];
}

//--------------------------------------------------------------
void ofxIOSDeviceMotion::stop(){
    [motion stop];
}

//--------------------------------------------------------------
void ofxIOSDeviceMotion::calibrate(){
    [motion calibrate];
}

//--------------------------------------------------------------
bool ofxIOSDeviceMotion::getIsDataNew(){
    return bIsDataNew;
}

//--------------------------------------------------------------
void ofxIOSDeviceMotion::setUseDeviceMotion(bool b){
    if(![motion isDeviceMotionAvailable]){
        ofLogError() << "Device Motion not available on this device!";
        b = false;
    }
    motion.bUseDeviceMotion = b;
}

//--------------------------------------------------------------
void ofxIOSDeviceMotion::setUseAccelerometer(bool b){
    if(![motion isAccelerometerAvailable]){
        ofLogError() << "Accelerometer not available on this device!";
        b = false;
    }
    motion.bUseAccelerometer = b;
}

//--------------------------------------------------------------
void ofxIOSDeviceMotion::setUseGyroscope(bool b){
    if(![motion isGyroAvailable]){
        ofLogError() << "Gyroscope not available on this device!";
        b = false;
    }
    motion.bUseGyroscope = b;
}

//--------------------------------------------------------------
void ofxIOSDeviceMotion::setUseMagnetometer(bool b){
    if(![motion isMagnetometerAvailable]){
        ofLogError() << "Magnetometer not available on this device!";
        b = false;
    }
    motion.bUseMagnetometer = b;
}

//--------------------------------------------------------------
bool ofxIOSDeviceMotion::getUseDeviceMotion(){
    return motion.bUseDeviceMotion;
}

//--------------------------------------------------------------
bool ofxIOSDeviceMotion::getUseAccelerometer(){
    return motion.bUseAccelerometer;
}

//--------------------------------------------------------------
bool ofxIOSDeviceMotion::getUseGyroscope(){
    return motion.bUseGyroscope;
}

//--------------------------------------------------------------
bool ofxIOSDeviceMotion::getUseMagnetometer(){
    return motion.bUseMagnetometer;
}

//--------------------------------------------------------------
ofPoint& ofxIOSDeviceMotion::getAcceleration(){
    bIsDataNew = false;
    return acceleration;
}

//--------------------------------------------------------------
ofPoint& ofxIOSDeviceMotion::getRotation(){
    bIsDataNew = false;
    return rotation;
}

//--------------------------------------------------------------
ofPoint& ofxIOSDeviceMotion::getAccelerationWithoutGravity(){
    bIsDataNew = false;
    return uacceleration;
}

//--------------------------------------------------------------
ofPoint& ofxIOSDeviceMotion::getAccelerationInstaneous(){
    bIsDataNew = false;
    return iaccelaration;
}

//--------------------------------------------------------------
ofPoint& ofxIOSDeviceMotion::getGravity(){
    bIsDataNew = false;
    return gravity;
}

//--------------------------------------------------------------
ofPoint& ofxIOSDeviceMotion::getAttitude(){
    bIsDataNew = false;
    return attitude;
}

//--------------------------------------------------------------
ofPoint& ofxIOSDeviceMotion::getMagnetometer(){
    bIsDataNew = false;
    return magnet;
}

//--------------------------------------------------------------
int& ofxIOSDeviceMotion::getTimeStampMillis(){
    return timestamp;
}

//--------------------------------------------------------------
void ofxIOSDeviceMotion::setSampleRate(float rate){
    sampleRate = rate;
    motion.accelerometerUpdateInterval = 1.0/sampleRate;
    motion.gyroUpdateInterval = 1.0/sampleRate;
    motion.magnetometerUpdateInterval = 1.0/sampleRate;
    motion.deviceMotionUpdateInterval = 1.0/sampleRate;
}

//--------------------------------------------------------------
float ofxIOSDeviceMotion::getSampleRate(){
    return sampleRate;
}

//--------------------------------------------------------------
string ofxIOSDeviceMotion::getSensorDataAsString(){
    
    ostringstream os;
    
    os << "SENSOR RATE: " << sampleRate << "/sec, last timestamp: " << getTimeStampMillis() << endl << endl;
    
    char msg[256];
    
    sprintf(msg, "Accel    Grav: x: %+.2f y: %+.2f z: %+.2f",
            getAcceleration().x, getAcceleration().y, getAcceleration().z);
    
    os << msg << endl;
    
    sprintf(msg, "Accel No Grav: x: %+.2f y: %+.2f z: %+.2f",
            getAccelerationWithoutGravity().x, getAccelerationWithoutGravity().y, getAccelerationWithoutGravity().z);
    
    os << msg << endl;
    
    sprintf(msg, "Accel Instant: x: %+.2f y: %+.2f z: %+.2f",
            getAccelerationInstaneous().x, getAccelerationInstaneous().y, getAccelerationInstaneous().z);
    
    os << msg << endl;
    
    sprintf(msg, "Gravity      : x: %+.2f y: %+.2f z: %+.2f",
            getGravity().x, getGravity().y, getGravity().z);
    
    os << msg << endl;
    
    sprintf(msg, "Rotation     : x: %+.2f y: %+.2f z: %+.2f",
            getRotation().x, getRotation().y, getRotation().z);
    
    os << msg << endl;
    
    sprintf(msg, "Attitude     : x: %+.2f y: %+.2f z: %+.2f",
            getAttitude().x, getAttitude().y, getAttitude().z);
    
    os << msg << endl;
    
    sprintf(msg, "Magnetometer : x: %+.2f y: %+.2f z: %+.2f",
            getMagnetometer().x, getMagnetometer().y, getMagnetometer().z);
    
    os << msg << endl;
    
    return os.str();
}