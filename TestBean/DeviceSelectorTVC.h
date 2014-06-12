//
//  DeviceSelectorTVC.h
//  MQTTiTag
//
//  Created by Nick Perez on 4/6/14.
//  Copyright (c) 2014 Nick Perez. All rights reserved.
//

@import QuartzCore;
@import CoreBluetooth;

@interface DeviceSelectorTVC : UITableViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@end
