#import "SettingsViewController.h"
#import "UserDefaultsHelper.h"

@interface SettingsViewController ()

typedef enum {
	SettingsSectionSwitch,
	SettingsSectionAction
}SettingSection;

typedef enum {
	SettingsActionRowClearSearchHistory
}SettingsActionRows;

@end

@implementation SettingsViewController
{
	NSUserDefaults *_defaults;
}

#pragma mark - ViewController Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	_defaults = [NSUserDefaults standardUserDefaults];
}

-(void)viewWillDisappear:(BOOL)animated {
	[_defaults synchronize];
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onDoneButton:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	switch (section) {
		case SettingsSectionSwitch:
			return 2;
			break;
		case SettingsSectionAction:
			return 1;
			break;
		default:
			return 0;
			break;
	}
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	switch (indexPath.section) {
		case SettingsSectionSwitch:
			cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
			[self setupCellForSwitchSection:cell atRow:indexPath.row];
			break;
		case SettingsSectionAction:
			cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
			[self setupCellForActionSection:cell atRow:indexPath.row];
			break;
	}
	return cell;
}

-(void)setupCellForSwitchSection:(UITableViewCell*)cell atRow:(NSInteger)row {
	
}

-(void)setupCellForActionSection:(UITableViewCell*)cell atRow:(NSInteger)row {
	switch (row) {
		case SettingsActionRowClearSearchHistory:
			cell.textLabel.text = @"Clear Search History";
			break;
	}
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case SettingsSectionSwitch:
			[self switchSectionDidSelectRow:indexPath.row];
			break;
		case SettingsSectionAction:
			[self actionSectionDidSelectRow:indexPath.row];
			break;
	}
}

-(void)switchSectionDidSelectRow:(NSInteger)row {
	
}

-(void)actionSectionDidSelectRow:(NSInteger)row {
	switch (row) {
		case SettingsActionRowClearSearchHistory:
			[_defaults setObject:[NSArray array] forKey:USER_PREF_PREVIOUS_SEARCHES];
			break;
	}
}

@end
