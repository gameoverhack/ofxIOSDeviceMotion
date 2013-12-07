#include "testApp.h"

//--------------------------------------------------------------
void testApp::setup(){	
	
    sampleRate = 60.0;
    ipAddress = "192.168.1.83";
    ipPort = 6666;
    
	//force landscape oreintation 
	iPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
    
//    motion.setUseDeviceMotion(false);
    motion.setSampleRate(sampleRate);
    motion.start();
    
//    ofSetFrameRate(sampleRate);
    
    bShowInfo = false;
    bShowHistory = true;
    
    // setup simple buttons
    float tSize = (float)ofGetHeight() / 3.0;
    
    btnReset.setup(ofGetWidth() - tSize, tSize * 0, tSize, tSize, "reset");
    btnShowHistory.setup(ofGetWidth() - tSize, tSize * 1, tSize, tSize, "history");
    btnShowInfo.setup(ofGetWidth() - tSize, tSize * 2, tSize, tSize, "info");
    btnRecord.setup(0, 0, tSize * 2, ofGetHeight(), "record");
    
    btnReset.setToggle(true);
    btnRecord.setToggle(true);
    
    btnShowHistory.setState(true);
    
    // setup keyboard
    keyboard = new ofxiPhoneKeyboard(tSize * 2 + 1, 0, tSize * 1.5, 18);
    keyboard->setVisible(true);
	keyboard->setBgColor(255, 255, 255, 255);
	keyboard->setFontColor(0,0,0, 255);
	keyboard->setFontSize(14);
    keyboard->setText(ipAddress + ":" + ofToString(ipPort));
    
    // setup osc
    ofLogNotice() << "Connecting to OSC server at:" << ipAddress << ":" << ipPort << endl;
    oscSender.setup(ipAddress, ipPort);
    bOscIsSetup = true;
    
	ofBackground(0, 0, 0);
}

//--------------------------------------------------------------
void testApp::update(){

    if(keyboard->isKeyboardShowing() && bOscIsSetup) bOscIsSetup = false;
    
    if(!keyboard->isKeyboardShowing() && !bOscIsSetup){
        
        cout << "heh: " << keyboard->getText() << endl;
        
        vector<string> ipPartsServer = ofSplitString(keyboard->getText(), ":");
        vector<string> ipAddressParts = ofSplitString(ipPartsServer[0], ".");
        
        if(ipPartsServer.size() == 1 || ipPartsServer.size() == 2){
            
            if(ipAddressParts.size() == 4){
                
                ipAddress = ipPartsServer[0];
                if(ipPartsServer.size() == 2){
                    ipPort = ofToInt(ipPartsServer[1]);
                }else{
                    ipPort = 6666;
                }
                
                // setup osc/netwroking
                
                ofLogNotice() << "Connecting to OSC server at:" << ipAddress << ":" << ipPort << endl;
                
                vector<string> ipPartsClient = ofSplitString(getIPAddress(), ".");
                clientID = ofToInt(ipPartsClient[ipPartsClient.size() - 1]);
                
                oscSender.setup(ipAddress, ipPort);
                bOscIsSetup = true;
                
            }else{ // if(ipAddressParts.size() == 4){
                return;
            }
        }else{ // if(ipPartsServer.size() == 1 || ipPartsServer.size() == 2){
            return;
        }

    } // if(!keyboard->isKeyboardShowing() && !bOscIsSetup){
    
    if(!motion.getIsDataNew()) return;
    
    ofPoint acceleration = motion.getAcceleration();
    ofPoint rotation = motion.getRotation();
    ofPoint gravity = motion.getGravity();
    ofPoint attitude = motion.getAttitude();
    ofPoint uacceleration = motion.getAccelerationWithoutGravity();
//    ofPoint iacceleration = motion.getAccelerationInstaneous();
    
    if(bShowHistory){
        
        if(accelerationHistory.size() == ofGetWidth()) accelerationHistory.clear();
        if(rotationHistory.size() == ofGetWidth()) rotationHistory.clear();
        if(attitudeHistory.size() == ofGetWidth()) attitudeHistory.clear();
        
        accelerationHistory.push_back(uacceleration);
        rotationHistory.push_back(rotation);
        attitudeHistory.push_back(attitude);
    }
    
    if(!bOscIsSetup) return;
    
    ofxOscMessage m;
    m.setAddress("/device");
    
    m.addIntArg(clientID);
    m.addIntArg(PHONETYPE_IPHONE);
    m.addIntArg(SERVERTYPE_MATTG);
    
    m.addIntArg(ofGetElapsedTimeMillis());
    
    m.addFloatArg(acceleration.x);
    m.addFloatArg(acceleration.y);
    m.addFloatArg(acceleration.z);
    
    m.addFloatArg(rotation.x);
    m.addFloatArg(rotation.y);
    m.addFloatArg(rotation.z);
    
    m.addFloatArg(attitude.x);
    m.addFloatArg(attitude.y);
    m.addFloatArg(attitude.z);
    
    m.addFloatArg(gravity.x);
    m.addFloatArg(gravity.y);
    m.addFloatArg(gravity.z);
    
    m.addFloatArg(uacceleration.x);
    m.addFloatArg(uacceleration.y);
    m.addFloatArg(uacceleration.z);
    
    oscSender.sendMessage(m);
}

//--------------------------------------------------------------
void testApp::draw(){
    
    btnReset.draw();
    btnShowHistory.draw();
    btnShowInfo.draw();
    btnRecord.draw();
    
    if(btnShowHistory.getState()){
        drawVector(0, (ofGetHeight() / 3.0f) * 0 + 30, 20, accelerationHistory, "acceleration");
        drawVector(0, (ofGetHeight() / 3.0f) * 1 + 30, 20, rotationHistory, "rotation");
        drawVector(0, (ofGetHeight() / 3.0f) * 2 + 30, 20, attitudeHistory, "attitude");
    }
    
    if(btnShowInfo.getState()){
        
        ofSetColor(255, 255, 255);
        
        ostringstream os;
        os << "FPS: " << ofGetFrameRate() << endl;
        os << motion.getSensorDataAsString() << endl;
        ofDrawBitmapString(os.str(), 20, 20);
        
    }
    
}

//--------------------------------------------------------------
void testApp::drawVector(float x, float y, float scale, vector<ofPoint> & vec, string label){
    if(vec.size() < 2) return;
    ofPushMatrix();
    ofTranslate(x, y);
    ofNoFill();
    ofSetColor(255, 255, 255);
    ofDrawBitmapString(label, 20.0f, -20.0f);
    for(int i = 0; i < vec.size() - 1; i++){
        ofPushMatrix();
        ofTranslate(0, scale * 0);
        ofSetColor(255, 0, 0);
        ofLine(i, vec[i].x * scale, i + 1, vec[i + 1].x * scale);
        ofPopMatrix();
        ofPushMatrix();
        ofTranslate(0, scale * 1);
        ofSetColor(0, 255, 0);
        ofLine(i, vec[i].y * scale, i + 1, vec[i + 1].y * scale);
        ofPopMatrix();
        ofPushMatrix();
        ofTranslate(0, scale * 2);
        ofSetColor(0, 0, 255);
        ofLine(i, vec[i].z * scale, i + 1, vec[i + 1].z * scale);
        ofPopMatrix();
    }
    ofPopMatrix();
}

//--------------------------------------------------------------
void testApp::exit(){

}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs & touch){
    
    if (touch.id == 1){
		
		if(!keyboard->isKeyboardShowing()){
			keyboard->openKeyboard();
			keyboard->setVisible(true);
		} else{
			keyboard->setVisible(false);
		}
		
	}
    
    btnReset.mousePressed(touch.x, touch.y);
    btnShowHistory.mousePressed(touch.x, touch.y);
    btnShowInfo.mousePressed(touch.x, touch.y);
    btnRecord.mousePressed(touch.x, touch.y);
    
    if(btnRecord.getState()){
        ofxOscMessage m;
        m.setAddress("/record");
        m.addIntArg(clientID);
        m.addIntArg(PHONETYPE_IPHONE);
        m.addIntArg(SERVERTYPE_MATTG);
        m.addIntArg(ofGetElapsedTimeMillis());
        m.addIntArg(1);
        oscSender.sendMessage(m);
    }
    
    if(btnReset.getState()){
        motion.calibrate();
        ofxOscMessage m;
        m.setAddress("/reset");
        m.addIntArg(clientID);
        m.addIntArg(PHONETYPE_IPHONE);
        m.addIntArg(SERVERTYPE_MATTG);
        m.addIntArg(ofGetElapsedTimeMillis());
        oscSender.sendMessage(m);
    }
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs & touch){
//    sampleRate =  60.0 * touch.y / (float)ofGetHeight();
//    motion.setSampleRate(sampleRate);
//    ofSetFrameRate(sampleRate);
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs & touch){
    
    bool bIsRecording = btnRecord.getState();

    btnReset.mouseReleased(touch.x, touch.y);
    btnShowHistory.mouseReleased(touch.x, touch.y);
    btnShowInfo.mouseReleased(touch.x, touch.y);
    btnRecord.mouseReleased(touch.x, touch.y);
    
    if(bIsRecording && !btnRecord.getState()){
        ofxOscMessage m;
        m.setAddress("/record");
        m.addIntArg(clientID);
        m.addIntArg(PHONETYPE_IPHONE);
        m.addIntArg(SERVERTYPE_MATTG);
        m.addIntArg(ofGetElapsedTimeMillis());
        m.addIntArg(0);
        oscSender.sendMessage(m);
    }
}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs & touch){
//    if(touch.x < ofGetWidth()/2.0f) bShowInfo = !bShowInfo;
//    if(touch.x > ofGetWidth()/2.0f) bShowHistory = !bShowHistory;
}

//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::lostFocus(){

}

//--------------------------------------------------------------
void testApp::gotFocus(){

}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){

}

//--------------------------------------------------------------
string testApp::getIPAddress(){
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    string wifiAddress = "";
    string cellAddress = "";
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if(sa_type == AF_INET || sa_type == AF_INET6) {
                string name = temp_addr->ifa_name;
                string addr = inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr); // pdp_ip0
                cout << "NAME: " << name << " ADDR: " << addr << endl;
                if(name == "en0" || name == "en1") {
                    // Interface is the wifi connection on the iPhone
                    wifiAddress = addr;
                } else
                    if(name == "pdp_ip0") {
                        // Interface is the cell connection on the iPhone
                        cellAddress = addr;
                    }
            }
            temp_addr = temp_addr->ifa_next;
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    string addr = wifiAddress != "" ? wifiAddress : cellAddress;
    return addr != "" ? addr : "0.0.0.0";
}
