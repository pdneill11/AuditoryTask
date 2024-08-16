// Define pin numbers for the speaker and lick-port inputs
const int speakerPin = 25; // Output pin associated with the speaker
const int lickleftPin = A10; // Input pin associated with lick left
const int lickrightPin = A11; // Input pin associated with lick right

// Define frequencies and duration for the test tones
const int ToneArray[2] = {3000, 12000}; // Frequencies of "test-tones" (3kHz, 12kHz)
const int toneDuration = 2000; // Duration of the "test-tones" in milliseconds (2s)

const int goTone = 6000; // Frequency of "go-tone" (6kHz)
const int goDuration = 500; // Duration of the "go-tone" (500ms)

const int delayDuration = 1000; // Duration of time between "test-tone" and "go-tone" (1s)

const int analogThresh = 100; // Threshold at which "lick-response" is registered

unsigned long startTime;
unsigned long responseTime;
bool inputReceived = false;

void setup() {
  // Initialize serial communication at 9600 bits per second
  Serial.begin(9600);
  
  // Set pin modes
  pinMode(speakerPin, OUTPUT);
  pinMode(lickleftPin, INPUT);
  pinMode(lickrightPin, INPUT);
}

void loop() {
  // Play a random "test-tone"
  int toneFreq = ToneArray[random(2)];
  tone(speakerPin, toneFreq, toneDuration);

  // Wait 1 second before playing "go-tone"
  unsigned long beginDelay = millis();

  while (millis() - beginDelay < delayDuration) {
    if (analogRead(lickleftPin) > analogThresh || analogRead(lickrightPin) > analogThresh) { // Adjust threshold as needed
      inputReceived = true;
      break;
    }
  }
  
  if (inputReceived) {
    Serial.println("False start!");
    inputReceived = false; // Reset the flag
    delay(5000); // Wait for 5 seconds before the next trial
    return; // Skip the rest of the loop and start over
  }
  
  // Play "go-tone"
  tone(speakerPin, goTone, goDuration);
  startTime = millis();

  // Measure response time
  while (true) {
    if (analogRead(lickleftPin) > analogThresh { // Adjust threshold as needed
      responseTime = millis() - startTime;
      Serial.print("Response time: ");
      Serial.print(responseTime);
      Serial.println(" ms");
      break;
    }
  }

  delay(5000); // Wait for 5 seconds before the next trial
}
