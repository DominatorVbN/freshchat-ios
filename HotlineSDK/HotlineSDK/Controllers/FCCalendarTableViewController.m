//
//  FCCalendarTableViewController.m
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 10/04/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCCalendarTableViewController.h"
#import "FCCalendarTableViewCell.h"
#import "FCTheme.h"

@interface FCCalendarTableViewController ()
@property(nonatomic, strong, retain) NSArray<FCCalendarDay*>* calendarDays;
@property(nonatomic, assign) BOOL showFullDays;
@property(nonatomic, retain, strong) FCCalendarDay *nextCalendar;
@end

@implementation FCCalendarTableViewController

-(id)initWithFullDays:(BOOL)showFullDays andDays:(nonnull NSArray<FCCalendarDay *> *)days {
    self = [self init];
    if(self) {
        self.calendarDays = days;
        self.showFullDays = showFullDays;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(!_showFullDays && self.calendarDays.count > 0) {
        [self constructNextShortCalendarSlot];
        return 1;
    }
    return self.calendarDays.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    FCCalendarDay *day = _showFullDays ? self.calendarDays[section] : _nextCalendar;
    int row = 0;
    row += day.morningSlots.count > 0 ? 1 : 0;
    row += day.afterNoonSlots.count > 0 ? 1 : 0;
    row += day.eveningSlots.count > 0 ? 1 : 0;
    row += day.nightSlots.count > 0 ? 1 : 0;
    return row;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FCCalendarTableViewCell *calendarCell;
    calendarCell = [tableView dequeueReusableCellWithIdentifier:@"FCCalendarCell"];
    if (!calendarCell) {
        calendarCell = [[FCCalendarTableViewCell alloc] initWithReuseIdentifier:@"FCCalendarCell"];
    }
    calendarCell.cellIndex = indexPath.row;
    
    FCCalendarDay *day = _showFullDays ? self.calendarDays[indexPath.section] : _nextCalendar;
    NSInteger actualRow = [tableView numberOfRowsInSection:indexPath.section];
    [calendarCell updateView:[day getSessionsIn:(int)indexPath.row] forLastCellInRow:actualRow - 1 == indexPath.row andLastRow: indexPath.section == tableView.numberOfSections - 1];
    return calendarCell;
}

- (void)clickedSlotDate:(NSDate *)date withTimeZone:(NSTimeZone *)zone {
    self.timeZone = zone.name;
    self.selectedSlotMillis = [date timeIntervalSince1970]*1000;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    FCTheme *theme = [FCTheme sharedInstance];
    NSString *labelName = self.calendarDays[section].dateString;
    UIView *view = [[UIView alloc]initWithFrame:CGRectZero];
    view.backgroundColor = [theme getCalendarPopupBackgroundColor];
    UILabel *label = [[UILabel alloc]init];
    label.translatesAutoresizingMaskIntoConstraints = false;
    [label setFont: [theme getCalendarSlotsDateTextFont]];
    [label setTextColor:[theme getCalendarSlotsDateTextColor]];
    label.textAlignment = NSTextAlignmentNatural;
    [label setText:labelName];
    [label sizeToFit];
    view.frame = CGRectMake(0, 0, label.frame.size.width + 15, label.frame.size.height + 20);
    [view addSubview:label];
    NSDictionary *views = @{@"label":label};
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[label]-15-|" options:0 metrics:nil views:views]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[label]-10-|" options:0 metrics:nil views:views]];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    FCTheme *theme = [FCTheme sharedInstance];
    NSString *labelName = [NSString stringWithFormat:@"%@",self.calendarDays[section].dateString];
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 0, 0)];
    [label setFont: [theme getCalendarSlotsDateTextFont]];
    [label setText:labelName];
    [label sizeToFit];
    return label.frame.size.height + 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

-(void)showFullDays:(BOOL)fullDays {
    if (_showFullDays != fullDays) {
        _showFullDays = !_showFullDays;
        [self.tableView reloadData];
    }
}

-(void)constructNextShortCalendarSlot {
    if (!_nextCalendar && self.calendarDays.count > 0 && !_showFullDays) {
        _nextCalendar = [self.calendarDays[0] copy];
        NSMutableArray<FCCalendarSession*>* morningSlots = [_nextCalendar.morningSlots mutableCopy];
        NSMutableArray<FCCalendarSession*>* afterNoonSlots = [_nextCalendar.afterNoonSlots mutableCopy];
        NSMutableArray<FCCalendarSession*>* eveningSlots = [_nextCalendar.eveningSlots mutableCopy];
        NSMutableArray<FCCalendarSession*>* nightSlots = [_nextCalendar.nightSlots mutableCopy];
        [_nextCalendar.morningSlots removeAllObjects];
        [_nextCalendar.afterNoonSlots removeAllObjects];
        [_nextCalendar.eveningSlots removeAllObjects];
        [_nextCalendar.nightSlots removeAllObjects];
        int row = 0;
        _nextCalendar.morningSlots = [self getRepalaceSlots:morningSlots forCurrentCount:&row];
        if(row < 8) {
            _nextCalendar.afterNoonSlots = [self getRepalaceSlots:afterNoonSlots forCurrentCount:&row];
            if(row < 8) {
                _nextCalendar.eveningSlots = [self getRepalaceSlots:eveningSlots forCurrentCount:&row];
                if(row < 8) {
                    _nextCalendar.nightSlots = [self getRepalaceSlots:nightSlots forCurrentCount:&row];
                }
            }
        }
    }
}

-(NSMutableArray<FCCalendarSession *>*)getRepalaceSlots:(NSMutableArray *)replaceSlot forCurrentCount:(int*) row {
    if(*row + replaceSlot.count > 8) {
        int oldRow = *row;
        *row += 8 - *row;
        return [[replaceSlot subarrayWithRange:NSMakeRange(0, 8 - oldRow)] mutableCopy];
    } else {
        *row += replaceSlot.count;
        return replaceSlot;
    }
}

- (void)changeSource:(NSArray<FCCalendarDay *> *)days {
    _calendarDays = days;
    _nextCalendar = nil;
    [self.tableView reloadData];
}
@end
