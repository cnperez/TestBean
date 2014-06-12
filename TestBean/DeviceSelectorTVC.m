//
//  DeviceSelectorTVC.m
//  MQTTiTag
//
//  Created by Nick Perez on 4/6/14.
//  Copyright (c) 2014 Nick Perez. All rights reserved.
//

#import "DeviceSelectorTVC.h"
#import "BeanViewController.h"

@interface DeviceSelectorTVC ()
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) NSMutableArray *beans; // need to retain peripherals or CB will give a warning
@end

@implementation DeviceSelectorTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.centralManager stopScan];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.centralManager.delegate = self;
    [self scanForPerhipherals];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.beans count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Device Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    CBPeripheral *peripheral = [self.beans objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", peripheral.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID: %@", [peripheral.identifier UUIDString]];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        NSInteger numTags = [self.beans count];
        return [NSString stringWithFormat:@"%ld Bean%@ found", (long)numTags, numTags == 1 ? @"":@"s"];
    }
    return @"";
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSLog(@"%@ Segue", segue.identifier);
    if ([segue.identifier isEqualToString:@"Select Bean"]) {
        //NSLog(@"Segue to BeanViewController");
        if ([segue.destinationViewController respondsToSelector:@selector(setBean:)]) {
            CBPeripheral *peripheral = [self.beans objectAtIndex:indexPath.row];
            [self.centralManager connectPeripheral:peripheral options:nil];
            [segue.destinationViewController performSelector:@selector(setCentralManager:) withObject:self.centralManager];
            [segue.destinationViewController performSelector:@selector(setBean:) withObject:peripheral];
            [segue.destinationViewController setTitle:((UITableViewCell *)sender).detailTextLabel.text];
        }
    }
}

#pragma mark - devices

- (NSMutableArray *)beans
{
    if (!_beans) {
        _beans = [[NSMutableArray alloc] init];
    }
    return _beans;
}

#pragma mark - CBCentralManagerDelegate

// CBCentralManagerDelegate
// This is called with the CBPeripheral class as its main input parameter.
// This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName isEqual:@"Bean"]) {
        NSLog(@"Discovered \"%@\" RSSI: %@", peripheral.name, RSSI);
        if (![self.beans containsObject:peripheral]) {
            [self.beans addObject:peripheral];
        }
        [self.tableView reloadData];
    }
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (!central) {
        central = self.centralManager;
    }
    
    NSString *message;
    if (central.state != CBCentralManagerStatePoweredOn) {
        // Determine the state of the peripheral
        switch (central.state)
        {
            case CBCentralManagerStateResetting:
                message = @"CoreBluetooth BLE hardware is resetting.";
                break;
            case CBCentralManagerStatePoweredOff:
                message = @"CoreBluetooth BLE hardware is powered off.";
                break;
            case CBCentralManagerStateUnauthorized:
                message = @"CoreBluetooth BLE state is unauthorized.";
                break;
            case CBCentralManagerStateUnsupported:
                message = @"CoreBluetooth BLE state is unsupported on this platform.";
                break;
            default:
                message = @"CoreBluetooth BLE state is unknown.";
                break;
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bluetooth unavailable"
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
       
    } else {
        message = @"CoreBluetooth BLE hardware is powered on and ready.";
        [self scanForPerhipherals];
    }
    NSLog(@"%@", message);
}

- (void)scanForPerhipherals
{
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        NSArray *services = nil;
        [self.centralManager scanForPeripheralsWithServices:services
                                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect!");
}

@end
