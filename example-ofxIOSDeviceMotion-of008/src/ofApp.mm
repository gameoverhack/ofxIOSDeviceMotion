#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){	
	
    sampleRate = 60.0;
    //ipAddress = "10.0.1.14";
    //ipPort = 6666;
    
    //manual yarp namespace configuration
    yarp::os::impl::NameConfig nc;
    nc.setManualConfig("10.0.1.104", 10000);
    //nc.setManualConfig("192.168.0.11", 10000);

    //get clientID (currently last digit of IP address)
    vector<string> ipPartsClient = ofSplitString(getIPAddress(), ".");
    clientID = ofToInt(ipPartsClient[ipPartsClient.size() - 1]);
    string clientIDs = "/iOSClient"+ofToString(clientID);
    bYarpPortOpen = port.open(clientIDs.c_str());
    
    
    //yarp connect command (expects dest port to exist!!)
    yarp::os::NetworkBase::connect(clientIDs.c_str(), "/motionReceiver");
    
	//force landscape oreintation 
	ofSetOrientation(OF_ORIENTATION_90_RIGHT);
    
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
    //ofLogNotice() << "Connecting to OSC server at:" << ipAddress << ":" << ipPort << endl;
    //oscSender.setup(ipAddress, ipPort);
    bOscIsSetup = true;
    
	ofBackground(0, 0, 0);
}

//--------------------------------------------------------------
void ofApp::update(){

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
    
    /*
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
    */
    
    if (!bYarpPortOpen)
        return;
    
    output = &port.prepare();
    output->clear();
    
    output->addString("/device");
    
    output->addInt(clientID);
    output->addInt(PHONETYPE_IPHONE);
    output->addInt(SERVERTYPE_MATTG);
    
    output->addInt(ofGetElapsedTimeMillis());
    
    output->addDouble(acceleration.x);
    output->addDouble(acceleration.y);
    output->addDouble(acceleration.z);
    
    output->addDouble(rotation.x);
    output->addDouble(rotation.y);
    output->addDouble(rotation.z);
    
    output->addDouble(attitude.x);
    output->addDouble(attitude.y);
    output->addDouble(attitude.z);
    
    output->addDouble(gravity.x);
    output->addDouble(gravity.y);
    output->addDouble(gravity.z);
    
    output->addDouble(uacceleration.x);
    output->addDouble(uacceleration.y);
    output->addDouble(uacceleration.z);
    
    port.write();
}

//--------------------------------------------------------------
void ofApp::draw(){
    
    btnReset.draw();
    btnShowHistory.draw();
    btnShowInfo.draw();
    btnRecord.draw();
    

    
    if(btnShowInfo.getState()){
        
        ofSetColor(255, 255, 255);
        
        ostringstream os;
        os << "FPS: " << ofGetFrameRate() << endl;
        os << motion.getSensorDataAsString() << endl;
        ofDrawBitmapString(os.str(), 20, 20);
        
    }
    
    if(btnShowHistory.getState()){
        drawVector(0, (ofGetHeight() / 3.0f) * 0 + 30, 20, accelerationHistory, "acceleration");
        drawVector(0, (ofGetHeight() / 3.0f) * 1 + 30, 20, rotationHistory, "rotation");
        drawVector(0, (ofGetHeight() / 3.0f) * 2 + 30, 20, attitudeHistory, "attitude");
    }
    
}

//--------------------------------------------------------------
void ofApp::drawVector(float x, float y, float scale, vector<ofPoint> & vec, string label){
    if(vec.size() < 2) return;
    
    ofEnableSmoothing();
    ofEnableAlphaBlending();
    ofSetLineWidth(1.0f);
    
    ofMesh meshX;
    ofMesh meshY;
    ofMesh meshZ;
    
    meshX.setMode(OF_PRIMITIVE_LINE_STRIP);
    meshY.setMode(OF_PRIMITIVE_LINE_STRIP);
    meshZ.setMode(OF_PRIMITIVE_LINE_STRIP);
    
    ofPushMatrix();
    ofTranslate(x, y);
    ofNoFill();
    ofSetColor(255, 255, 255);
    ofDrawBitmapString(label, 20.0f, -20.0f);
    for(int i = 0; i < vec.size() - 1; i++){
        int dx = i;
        //ofPushMatrix();
        //ofTranslate(0, scale * 0);
        //ofSetColor(255, 0, 0);
        meshX.addColor(ofColor(255,0,0));
        meshX.addVertex(ofVec2f(dx+x, vec[i].x * scale + y));
        //ofLine(dx, vec[i].x * scale, dx + 1, vec[i + 1].x * scale);
        //ofPopMatrix();
        //ofPushMatrix();
        ofTranslate(0, scale * 1);
        //ofSetColor(0, 255, 0);
        meshY.addColor(ofColor(0,255,0));
        meshY.addVertex(ofVec2f(dx + x, vec[i].y * scale + y + scale));
        //ofLine(dx, vec[i].y * scale, dx + 1, vec[i + 1].y * scale);
        //ofPopMatrix();
        //ofPushMatrix();
        //ofTranslate(0, scale * 2);
        //ofSetColor(0, 0, 255);
        meshZ.addColor(ofColor(0,0,255));
        meshZ.addVertex(ofVec2f(dx + x, vec[i].z * scale + y + 2*scale));
        //ofLine(dx, vec[i].z * scale, dx + 1, vec[i + 1].z * scale);
        //ofPopMatrix();
    }
    ofPopMatrix();
    
    meshX.draw();
    meshY.draw();
    meshZ.draw();
}

//--------------------------------------------------------------
void ofApp::exit(){
    
    port.close();

}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    
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
        
        output = &port.prepare();
        output->clear();
        output->addString("/record");
        output->addInt(clientID);
        output->addInt(PHONETYPE_IPHONE);
        output->addInt(SERVERTYPE_MATTG);
        output->addInt(ofGetElapsedTimeMillis());
        output->addInt(1);
        while (port.isWriting());// we want to wait until port is done!
        port.write();
        
        return; //ignore osc stuff
        
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
        
        
        output = &port.prepare();
        output->clear();
        output->addString("/reset");
        output->addInt(clientID);
        output->addInt(PHONETYPE_IPHONE);
        output->addInt(SERVERTYPE_MATTG);
        output->addInt(ofGetElapsedTimeMillis());
        while (port.isWriting()); // we want to wait until port is done!
        port.write();
        
        return; //ignore osc stuff
        
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
void ofApp::touchMoved(ofTouchEventArgs & touch){
//    sampleRate =  60.0 * touch.y / (float)ofGetHeight();
//    motion.setSampleRate(sampleRate);
//    ofSetFrameRate(sampleRate);
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    
    bool bIsRecording = btnRecord.getState();

    btnReset.mouseReleased(touch.x, touch.y);
    btnShowHistory.mouseReleased(touch.x, touch.y);
    btnShowInfo.mouseReleased(touch.x, touch.y);
    btnRecord.mouseReleased(touch.x, touch.y);
    
    return; //ignore OSC
    
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
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){
//    if(touch.x < ofGetWidth()/2.0f) bShowInfo = !bShowInfo;
//    if(touch.x > ofGetWidth()/2.0f) bShowHistory = !bShowHistory;
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}

//--------------------------------------------------------------
string ofApp::getIPAddress(){
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
