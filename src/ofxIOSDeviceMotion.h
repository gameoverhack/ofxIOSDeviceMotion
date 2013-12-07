/*
 * ofxIOSDeviceMotion.h
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

#ifndef _H_OFXIOSDEVICEMOTION
#define _H_OFXIOSDEVICEMOTION

#include "ofMain.h"
#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

#ifdef __OBJC__
@class _ofxIOSDeviceMotion;
#endif

class ofxIOSDeviceMotion {
    
public:
	
    ofxIOSDeviceMotion();
    ~ofxIOSDeviceMotion();
    
//    void setup();
    
    void start();
    void stop();
    void calibrate();
    
    void setSampleRate(float rate);
    float getSampleRate();
    
    bool getIsDataNew();
    
    void setUseDeviceMotion(bool b); // defualt true when available
    void setUseAccelerometer(bool b); // default true
    void setUseGyroscope(bool b); // default true
    void setUseMagnetometer(bool b); // default false
    
    bool getUseDeviceMotion();
    bool getUseAccelerometer();
    bool getUseGyroscope();
    bool getUseMagnetometer();
    
    ofPoint& getAcceleration();
    ofPoint& getAccelerationWithoutGravity();
    ofPoint& getAccelerationInstaneous();
    ofPoint& getRotation();
    ofPoint& getGravity();
    ofPoint& getAttitude();
    ofPoint& getMagnetometer();
    
    int& getTimeStampMillis();
    
    string getSensorDataAsString();
    
    bool bIsDataNew; // ugly
    
protected:
    
    ofPoint acceleration;
    ofPoint iaccelaration;
    ofPoint uacceleration;
    ofPoint rotation;
    ofPoint attitude;
    ofPoint gravity;
    ofPoint magnet;

    int timestamp;
    
    float sampleRate;
    
#ifdef __OBJC__
	_ofxIOSDeviceMotion* motion;
#else
	void* ftp;
#endif
    
private:
	
};

#endif
