//
//  BeanViewController.h
//  TestBean
//
//  Created by Nick Perez on 6/8/14.
//  Copyright (c) 2014 Nick Perez. All rights reserved.
//

#import "DeviceSelectorTVC.h"
@import QuartzCore;
@import CoreBluetooth;

@interface BeanViewController : UIViewController <CBPeripheralDelegate, UITextFieldDelegate>
@property (strong, nonatomic) CBPeripheral *bean;
@property (strong, nonatomic) CBCentralManager *centralManager;
@end
