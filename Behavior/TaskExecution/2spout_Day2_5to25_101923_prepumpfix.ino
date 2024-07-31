
//this version of the code was modified from the 2spout_TrainingDay1_101723 by adding 2 new variables (prepump and preloadvolume) 
//to get rid of the delay between the trial start ttl and the led turning on, which was caused by the 1000ms delay between the digitalWrite(pumptrigger, HIGH) and digitalWrite(pumptrigger, LOW) lines

#include <Servo.h>
#include <SoftwareSerial.h>

Servo servoMotor;  // Create a servo object

//Variable Volume Control Setup
#define NUMBER_OF_TRIALS 60
const int volumes[NUMBER_OF_TRIALS] = {
  500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, 500, // 5ul
  1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, // 10ul
  1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500,  1500, 1500, // 15ul
  2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000,  // 20ul
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 // 0ul 
};

int trials[NUMBER_OF_TRIALS];
int trialsFinished;

//End Variable Volume Control Setup


// Set the PWM output pins
const int servoPin1 = 2;  // Set the servo pin number
const int servoPin2 = 3;  // Set the servo pin number
const int servoPin3 = 4;   // Set the servo pin number
const int speakerPin1 = 5; // Set the speaker pin number
const int randomnoise = A0; //This is to help the randomseed function generate a better pseudorandom sequence

// Set the led pins
const int  irled = 40;  //infrared led indicator for trial state
const int  led1 = 42;   //led indicator at reward spout 1
const int  led2 = 44;   //led indicator at reward spout 2
const int  led3 = 46;   //led indicator at reward spout 3
const int  led4 = 48;   //led indicator at reward spout 4

//Set the pins for the capactive lick sensing
const int lick1 = 32;   //capacitive touch sensor at spout 1
const int lick2 = 34;   //capacitive touch sensor at spout 2
const int lick3 = 36;   //capacitive touch sensor at spout 3
const int lick4 = 38;   //capacitive touch sensor at spout 4

//Set the pins for tracking which lick sensor and LED are relevant on each trial
int licknow = 4;
int lednow = 0;

int rewardlocation = 0;    //this variable is assigned by either key press or the random function to dictate the active spout
int lastrewardlocation = 0; //this is to keep track of whether the spout changes from trial to trial
int reward = 4;             //this is to dictate which led to turn on
int prevreward = 0;         //this is used as a logic gate to control whether to preload the spout on the next trial   
int rewardstate = 0;        //inidicator of whether reward was earned during current trial (0 = no, 1 = yes)
int trialstate = 0;         //indicator of whether present epoch is during a trial (1) or an intertrial interval (0)
int rewardcount = 0;        //counts numbers of rewards earned
int restartstate = 0;       //logic gate to control the sequencing of actions during trials (0 = trial in progress, 1 = trial ended, 2 = trial should restart)
int trialcount = 0;         //counts numbers of trials
int preloadstate = 1;       //logic gate to dictate whether or not to preload the active spout with some reward
int pumpstate = 0;          //indicator of current pump state (0 = idle, 1 = active)


int rewardvol = 1000;       //This is the length of time (ms) to run the braintree syringe pump program (pumps @ 10ul/sec when in ttl tr:LE mode)
int lick1state = HIGH;      //encodes lick detection
int prevlick1state = HIGH;  //encodes lick detection

int lick2state = HIGH;      //encodes lick detection
int prevlick2state = HIGH;  //encodes lick detection

int lick3state = HIGH;      //encodes lick detection
int prevlick3state = HIGH;  //encodes lick detection

int lick4state = HIGH;
int prevlick4state = HIGH;

//There are 6 ttl lines below: trial (led/sound), pump, spouts1-4
const int trialttl = 8; // trialStart or trialEnd ttl
const int loomttl = 9;  // loom trigger ttl

//Define the lick detection ttl output pins
const int spout1ttl = 10;           // contact at spout 1
//const int spout2ttl = 11;         // contact at spout 2   #think I can only have 4 bnc inputs to photom box
//const int spout3ttl = 12;         // contact at soout 3    #think I can only have 4 bnc inputs to photom box
const int spout4ttl = 11;           // contact at spout 4 

const int pumptrigger = 52; //this is the output pin that controls the pump

unsigned long rewardcuestart = 0;   //timer for the start of the trial
signed long pumpstart = -5001;      //timer for the pump
unsigned long licktime = 0;         //timer for licks
unsigned long rewardtime = 0;       //timer for reward delivery
unsigned long restarttime = 0;      //timer for restart sequences
unsigned long trialend = 0;         //timer for trial end
unsigned long interval = 30000;     //variable ITI 
unsigned long triallength = 30000;  //constant trial length

int preloadvolume = 500;           //This is the length of time (ms) to run the braintree pump at the start of each preloaded trial #####
signed long prepump = -5001;        //timer for the pump to preload reward #####
int prepumpstate = 0;               //indicator of pump state during reward preloading (0 = idle, 1 = active)

void setup() {
  Serial.begin(9600);

  //Set up the hardware outputs
  pinMode(led1, OUTPUT);
  pinMode(led2, OUTPUT);
  pinMode(led3, OUTPUT);
  pinMode(led4, OUTPUT);
  pinMode(irled, OUTPUT);
  pinMode(pumptrigger, OUTPUT);
  pinMode(speakerPin1, OUTPUT);
  
  //Set ttl generating pins as outputs
  pinMode(spout1ttl, OUTPUT);
  //pinMode(spout2ttl, OUTPUT);
  //pinMode(spout3ttl, OUTPUT);
  pinMode(spout4ttl, OUTPUT);
  pinMode(loomttl, OUTPUT);
  pinMode(trialttl, OUTPUT);

  //Set up the input pins (cap touch sensors)
  pinMode(lick1, INPUT);
  pinMode(lick2, INPUT);
  pinMode(lick3, INPUT);
  pinMode(lick4, INPUT);
  
  pinMode(randomnoise, INPUT);          //For pseudorandom trial variables (rewardvolume)
  randomSeed(analogRead(randomnoise));  //For pseudorandom trial variables (rewardvolume)
  resetRewardVols();
}

void loop() {
  if (Serial.available() > 0) {

    rewardlocation = Serial.parseInt();  // Read the incoming serial data
    //Serial.println(rewardstate);
  }

  // Change the servo-controlled valves to specify location of milk delivery
  if (rewardlocation == 1) {
    servoMotor.attach(servoPin1, 553, 2520);  // Attach the servo to the pin
    servoMotor.write(90);  // Move to 90 degres
    delay(500);  // Wait for the servo to reach the desired position
    servoMotor.detach();

    //Serial.println("Reward Port 1 Active");
    reward = 1;
    lednow = led1;
    licknow = 32;
    rewardlocation = 0;

  } 

  else if (rewardlocation == 2) {
    servoMotor.attach(servoPin1, 553, 2520);  // Attach the servo to the pin
    servoMotor.write(180);  // Move valve 1 to 180 degres
    delay(500);  // Wait for the servo to reach the desired position
    servoMotor.detach();

    //servoMotor.attach(servoPin2, 553, 2520);  // Attach the servo to the pin
    //servoMotor.write(90);  // Move valve 2 to 180 degres
    //delay(500);  // Wait for the servo to reach the desired position


    //servoMotor.attach(servoPin3, 553, 2520);  // Attach the servo to the pin
    //servoMotor.write(90);  // Move valve 3 to 90 degres
    //delay(500);  // Wait for the servo to reach the desired position
    //servoMotor.detach();

    //Serial.println("Reward Port 4 Active");
    reward = 4;
    licknow = 38;
    rewardlocation = 0;
  }

  //Start the trial
  if (rewardlocation == 9) {
    Serial.print("Trial ");
    trialcount += 1;
    Serial.print(trialcount);
    Serial.print(" started, spout ");
    trialstate = 1;
    rewardcuestart = millis();
    Serial.print(reward);
    Serial.print(" is active, ");
    Serial.println(rewardcuestart);
    tone(speakerPin1, 4000, 2000); 
    rewardlocation = reward;
    digitalWrite(irled, HIGH);
    digitalWrite(trialttl, HIGH);
    delay(10);
    digitalWrite(trialttl, LOW);

    if ((preloadstate == 1)) {
      digitalWrite(pumptrigger, HIGH);
      prepumpstate = 1;
      prepump = millis();
    }
    
    if (preloadstate == 0) {
      Serial.print("Prev Trial Failed, Reward Left Over, ");
      Serial.println(millis());
    }


    if (reward == 1) {
      digitalWrite(led1, HIGH);
    }
    else if (reward == 2) {
      digitalWrite(led2, HIGH);
    }
    else if (reward == 3) {
      digitalWrite(led3, HIGH);
    }
    else if (reward == 4) {
      digitalWrite(led4, HIGH);
    }
  }

  if (((millis() - prepump) > preloadvolume) && (millis() - prepump < 5000) && (prepumpstate  == 1)) { // if (((millis() - pumpstart) > rewardvol) && (millis() - pumpstart < 6000) && (rewardstate  == 0))
    digitalWrite(pumptrigger, LOW);
    prepumpstate = 0;
    Serial.print("Reward preloaded, ");
    Serial.print(preloadvolume);
    Serial.print("ms, ");
    Serial.println(millis());
  }
  
  if (((millis() - pumpstart) > rewardvol) && (millis() - pumpstart < 5000) && (rewardstate  == 0)) { // if (((millis() - pumpstart) > rewardvol) && (millis() - pumpstart < 6000) && (rewardstate  == 0))
    digitalWrite(pumptrigger, LOW);
    pumpstate = 0;
    Serial.print(rewardvol);
    Serial.print("ms Milk Delivered, spout ");
    Serial.print(reward);
    Serial.print(", ");
    rewardtime = millis();
    Serial.println(rewardtime);
    rewardstate = 1;
    rewardcount += 1;
  }

  lick1state = digitalRead(lick1);
  if (lick1state != prevlick1state) {
    if (digitalRead(lick1) == LOW) {
      if ((licknow == lick1) && (rewardstate  == 0)  && (trialstate == 1) && (pumpstate == 0)) {
        digitalWrite(pumptrigger, HIGH); 
        pumpstart = millis();
        pumpstate = 1;
      }
      licktime = millis();
      digitalWrite(spout1ttl, HIGH);
      delay(10);
      digitalWrite(spout1ttl, LOW);
      Serial.print("Lick detected, spout 1, ");
      Serial.println(licktime);
    }
  }
  prevlick1state = lick1state;


//  lick2state = digitalRead(lick2);
//  if (lick2state != prevlick2state) {
//    if (digitalRead(lick2) == LOW)  {
//      if ((licknow == lick2) && (rewardstate  == 0)  && (trialstate == 1) && (pumpstate == 0)) {
//        digitalWrite(pumptrigger, HIGH); 
//        pumpstart = millis();
//        pumpstate = 1;
//      }
//      licktime = millis();
//      digitalWrite(spout2ttl, HIGH);
//      delay(10);
//      digitalWrite(spout2ttl, LOW);
//      Serial.print("Lick detected, spout 2, ");
//      Serial.println(licktime);
//    }
//  }
//  prevlick2state = lick2state;

//  lick3state = digitalRead(lick3);
//  if (lick3state != prevlick3state) {
//    if (digitalRead(lick3) == LOW) {
//      if ((licknow == lick3) && (rewardstate  == 0)  && (trialstate == 1) && (pumpstate == 0)) {
//        digitalWrite(pumptrigger, HIGH); 
//        pumpstart = millis();
//        pumpstate = 1;
//      }
//      licktime = millis();
//      digitalWrite(spout3ttl, HIGH);
//      delay(10);
//      digitalWrite(spout3ttl, LOW);
//      Serial.print("Lick detected, spout 3, ");
//      Serial.println(licktime);
//    }
//  }
//  prevlick3state = lick3state;

  lick4state = digitalRead(lick4);
  if (lick4state != prevlick4state) {
    if (digitalRead(lick4) == LOW) {
      licktime = millis();
      digitalWrite(spout4ttl, HIGH);
      delay(10);
      digitalWrite(spout4ttl, LOW);
      Serial.print("Lick detected, spout 4, ");
      Serial.println(licktime);
      if ((licknow == lick4) && (rewardstate  == 0)  && (trialstate == 1) && (pumpstate == 0)) {
        digitalWrite(pumptrigger, HIGH); 
        pumpstart = millis();
        pumpstate = 1;
      }
    }
  }
  prevlick4state = lick4state;


  if ((trialstate == 1) && (rewardstate == 1) && (millis() - rewardtime) > 5000) {
    Serial.print("Trial ");
    Serial.print(trialcount);
    Serial.print(" is ending, reward earned, ");
    digitalWrite(led1, LOW);
    digitalWrite(led2, LOW);
    digitalWrite(led3, LOW);
    digitalWrite(led4, LOW);
    digitalWrite(irled, LOW);
    preloadstate = 1;
    trialstate = 0;
    rewardstate = 0;
    trialend = millis();
    Serial.println(trialend);
    digitalWrite(trialttl, HIGH);
    delay(10);
    digitalWrite(trialttl, LOW);
    interval = random(20000, 40000); 
    restartstate = 1;
    
    int volumeId = selectRandomRewardVolFromRemaining();
    if(volumeId == -1)
    {
      Serial.print("Full Reward Cycle Complete, ");
      Serial.print("Restarting, ");
      Serial.println(millis());
      resetRewardVols();
      delay(5000);
    }
    else
    {
      rewardvol = volumes[volumeId];
    }
  }

  if ((trialstate == 1) && (rewardstate == 0) && ((millis() - rewardcuestart) >= triallength)) {
    Serial.print("Trial ");
    Serial.print(trialcount);
    Serial.print(" is ending, no reward earned, ");
    digitalWrite(led1, LOW);
    digitalWrite(led2, LOW);
    digitalWrite(led3, LOW);
    digitalWrite(led4, LOW);
    digitalWrite(irled, LOW);
    preloadstate = 0;
    rewardstate = 0;
    trialstate = 0;
    trialend = millis();
    Serial.println(trialend);
    digitalWrite(trialttl, HIGH);
    delay(10);
    digitalWrite(trialttl, LOW);
    restartstate = 1;
    interval = random(20000, 40000);
  }

  if (reward != prevreward) {
    preloadstate = 1;
  }
  prevreward = reward;

  if ((restartstate == 1) && ((millis() - trialend) >= interval)) { 
    rewardlocation = random(1, 3);
    restarttime = millis();
    restartstate = 2;
  }

  if ((restartstate == 2) && (millis() - restarttime > 3000) ){ // allow 3 seconds for servos to do their thing, etc
    restartstate = 0; 
    rewardlocation = 9; // start a new trial
  }

  if (rewardlocation == 7) {
    Serial.print("Loom Presented during Trial ");
    Serial.print(trialcount);
    Serial.print(", spout ");
    unsigned long loomstart = millis();
    Serial.print(reward);
    Serial.print(" is active, ");
    Serial.println(loomstart);
    digitalWrite(loomttl, HIGH);
    delay(10);
    digitalWrite(loomttl, LOW);
  }

}

int selectRandomRewardVolFromRemaining()
{
  if(trialsFinished >= NUMBER_OF_TRIALS)
  {
    return -1;
  }
  int selection = random(trialsFinished, NUMBER_OF_TRIALS);
  int temp = trials[trialsFinished];
  trials[trialsFinished] = trials[selection];
  trials[selection] = temp;
  return trials[trialsFinished++]; //moved incrementing trialsFinished to here
}

bool resetRewardVols()
{
  for (int i = 0; i < NUMBER_OF_TRIALS; i++)
  {
    trials[i] = i;
  }
  for (int i = 0; i < NUMBER_OF_TRIALS; i++)
  {
    int index = random(i, NUMBER_OF_TRIALS);
    int temp = trials[i];
    trials[i] = trials[index];
    trials[index] = temp;
  }
  trialsFinished = 0;
}
