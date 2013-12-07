#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "ofxIOSDeviceMotion.h"
#include "ofxOsc.h"

#import <ifaddrs.h>
#import <arpa/inet.h>

enum PhoneType{
    PHONETYPE_IPHONE = 0,
    PHONETYPE_ANDROID
};

enum ServerType{
    SERVERTYPE_MATTG = 0,
    SERVERTYPE_MATTL,
    SERVERTYPE_NORMJ
};

class SimpleButton {
public:
    
    SimpleButton(){
        setup(0, 0, 0, 0);
        bIsToggle = false;
        bIsActive = false;
        name = "";
    }
    
    ~SimpleButton(){}
    
    void setup(float x, float y, float w, float h, string n = ""){
        setPosition(x, y);
        setSize(w, h);
        setName(n);
    }
    
    void setName(string n){
        name = n;
    }
    
    void setToggle(bool b){
        bIsToggle = b;
    }
    
    void setState(bool b){
        bIsActive = b;
    }
    
    bool getState(){
        return bIsActive;
    }
    
    void setPosition(float x, float y){
        r.x = x;
        r.y = y;
    }
    void setSize(float w, float h){
        r.width = w;
        r.height = h;
    }
    
    void draw(){
        ofFill();
        if(bIsActive){
            ofSetColor(255, 127, 127);
        }else{
            ofSetColor(127, 127, 127);
        }
        ofRect(r);
        ofNoFill();
        ofSetColor(190, 190, 190);
        ofRect(r);
        ofSetColor(0, 0, 0);
        ofDrawBitmapString(name, r.x + 5, r.y + r.height - 5);
    }
    
    void mousePressed(float x, float y){
        if(!bIsToggle) return;
        if(r.inside(x, y)){
            bIsActive = true;
        }
    }
    
    void mouseReleased(float x, float y){
        if(r.inside(x, y)){
            if(bIsToggle){
                bIsActive = false;
            }else{
                bIsActive = !bIsActive;
            }
        }
    }
    
protected:
    
    bool bIsToggle;
    bool bIsActive;
    ofRectangle r;
    string name;
    
};

class ofApp : public ofxiPhoneApp{
    
public:
    
    void setup();
    void update();
    void draw();
    void exit();
	
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);

    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    string getIPAddress();
    
    ofxIOSDeviceMotion motion;
    
    void drawVector(float x, float y, float scale, vector<ofPoint> & vec, string label = "");
    
    vector<ofPoint> accelerationHistory;
    vector<ofPoint> rotationHistory;
    vector<ofPoint> attitudeHistory;
    
    bool bShowInfo, bShowHistory;
    
    string ipAddress;
    int ipPort;
    
    bool bOscIsSetup;
    ofxOscSender oscSender;
    int clientID;
    
    SimpleButton btnIP;
    SimpleButton btnRecord;
    SimpleButton btnReset;
    SimpleButton btnShowInfo;
    SimpleButton btnShowHistory;
    
    float sampleRate;
    
    ofxiPhoneKeyboard* keyboard;
    
};