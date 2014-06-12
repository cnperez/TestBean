//
//  BeanViewController.m
//  TestBean
//
//  Created by Nick Perez on 6/8/14.
//  Copyright (c) 2014 Nick Perez. All rights reserved.
//

#import "BeanViewController.h"

#define BEAN_SERIAL_SERVICE_UUID @"A495FF10-C5B1-4B44-B512-1370F02D74DE"
#define BEAN_SERIAL_CHAR_UUID    @"A495FF11-C5B1-4B44-B512-1370F02D74DE"

@interface BeanViewController ()
@property (strong, nonatomic) CBCharacteristic *serialCharacteristic;
@property (weak, nonatomic) IBOutlet UISwitch *lightSwitch;
@property (weak, nonatomic) IBOutlet UISlider *redSlider;
@property (weak, nonatomic) IBOutlet UISlider *greenSlider;
@property (weak, nonatomic) IBOutlet UISlider *blueSlider;
@end

// helper

NSMutableData * hexStringToSerialData(NSString *hexString)
{
    // the first byte starts at 0x80 and increments by 0x20 each successive call
    // after 0xE0, reset back to 0x80 - not sure why it be like it is, but it do
    static const unsigned char initialVal = 0x80, maxVal = 0xE0, incVal = 0x20;
    static unsigned char first_byte = initialVal;
    hexString = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *serialData = [[NSMutableData alloc] init];
    [serialData appendBytes:&first_byte length:1];
    first_byte = first_byte >= maxVal ? initialVal : first_byte + incVal;
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [hexString length]/2; i++) {
        byte_chars[0] = [hexString characterAtIndex:i*2];
        byte_chars[1] = [hexString characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [serialData appendBytes:&whole_byte length:1];
    }
    return serialData;
}

@implementation BeanViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.bean.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self deconfigureBean];
    self.bean.delegate = nil;
    [self.centralManager cancelPeripheralConnection:self.bean];
    self.bean = nil;
}

#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"Scanning services...");
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:BEAN_SERIAL_SERVICE_UUID]]) {
            NSLog(@"Serial service found: %@", service.UUID);
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:BEAN_SERIAL_CHAR_UUID]]
                                     forService:service];
        }
    }
}

// Invoked when you discover the characteristics of a specified service.

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Characteristics for service: %@", service.UUID);
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BEAN_SERIAL_CHAR_UUID]]) {
            NSLog(@"Found serial connection characteristic");
            self.serialCharacteristic = characteristic;
            [self.bean setNotifyValue:YES forCharacteristic:characteristic];
            [self turnOffLED];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    //NSLog(@"didUpdateValueForCharacteristic %@, value = %@, error = %@", characteristic.UUID, characteristic.value, error.localizedDescription);
    if (!error) {
        // do something - maybe update UI or log value
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateNotificationStateForCharacteristic %@, error = %@", characteristic.UUID, error.localizedDescription);
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    //NSLog(@"didWriteValueForCharacteristic %@, error = %@", characteristic.UUID, error.localizedDescription);
}

- (void)deconfigureBean
{
    NSLog(@"Deconfiguring Bean...");
    [self turnOffLED];
    [self.bean setNotifyValue:NO forCharacteristic:self.serialCharacteristic];
    
}

- (void)sendSerialCommand:(NSString *)command
{
    [self.bean writeValue:hexStringToSerialData(command)
        forCharacteristic:self.serialCharacteristic
                     type:CBCharacteristicWriteWithResponse];
}

#pragma mark - LED 

- (void)turnOffLED
{
    NSString *commandString = @"05 00 20 01 00 00 00 69 F6";
    [self sendSerialCommand:commandString];
}

- (void)setLEDColorRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue
{
    NSString *commandString = [NSString stringWithFormat:@"05 00 20 01 %02x %02x %02x 0A 39", red, green, blue];
    NSLog(@"%@", commandString);
    [self sendSerialCommand:commandString];
}

#pragma mark - User Interface

- (IBAction)updateLED
{
    if (self.lightSwitch.on) {
        NSInteger r = self.redSlider.value;
        NSInteger g = self.greenSlider.value;
        NSInteger b = self.blueSlider.value;
        [self setLEDColorRed:r green:g blue:b];
    } else {
       [self turnOffLED];
    }
}

@end
