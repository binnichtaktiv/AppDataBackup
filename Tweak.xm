#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "SSZipArchive/SSZipArchive.h"
#import "JGProgressHUD/JGProgressHUD.h"

NSString *home = NSHomeDirectory();
NSString *tmp = NSTemporaryDirectory();
	

@interface ViewController : UIViewController <UIDocumentPickerDelegate>
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self showBackupRestoreOptions];
}
	
- (void)showBackupRestoreOptions {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Backup/Restore"
                                                                             message:@"This tweak can backup and restore your app data.\n\nPlease inject this tweak only if you want to backup or restore your app data to avoid problems. After you have created or restored your backup, remove the tweak again.\n\nmade by Chocolate Fluffy and binnichtaktiv ❤️"
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *backupAction = [UIAlertAction actionWithTitle:@"Backup" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self backupImportantDirectories];
    }];
    
    UIAlertAction *restoreAction = [UIAlertAction actionWithTitle:@"Restore" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self restoreBackup];
    }];
	 
    UIAlertAction *donateAction = [UIAlertAction actionWithTitle:@"Donate" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://binnichtaktiv.github.io/donate"] options:@{} completionHandler:nil];
    }];
    
    // Ändern Sie die Farbe des Donate-Buttons zu Grün
    [donateAction setValue:[UIColor greenColor] forKey:@"titleTextColor"];
	 
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss"
	     style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			  [self dismissViewControllerAnimated:YES completion:nil];
	 }];
    
    [alertController addAction:backupAction];
    [alertController addAction:restoreAction];
    [alertController addAction:donateAction];
	 [alertController addAction:dismissAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

//Backing Up and showing progress HUD
- (void)backupImportantDirectories {
    NSString *Documents = [home stringByAppendingPathComponent:@"Documents"];
    NSString *Library = [home stringByAppendingPathComponent:@"Library"];
    NSString *preferences = [Library stringByAppendingPathComponent:@"Preferences"];
    
    NSString *DocumentsZip = [tmp stringByAppendingPathComponent:@"Documents.zip"];
    NSString *LibraryZip = [tmp stringByAppendingPathComponent:@"Library.zip"];
    NSString *preferencesZip = [tmp stringByAppendingPathComponent:@"Preferences.zip"];
    
    NSString *BackupZip = [tmp stringByAppendingPathComponent:@"appBackup.zip"];
    
    Class SSZIP = objc_getClass("SSZipArchive");
    
    // Create and show progress HUD
    JGProgressHUD *hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    hud.textLabel.text = @"Zipping...";
    [hud showInView:self.view];
    
    // Use a dispatch queue for zipping
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL isDocumentZipped = [SSZIP createZipFileAtPath:DocumentsZip withContentsOfDirectory:Documents keepParentDirectory:NO withPassword:nil andProgressHandler:^(NSUInteger total, NSUInteger current) {
            dispatch_async(dispatch_get_main_queue(), ^{
					 hud.detailTextLabel.text = [NSString stringWithFormat:@"%ld/%ld", total, current];
            });
        }];
        
        BOOL isPreferencesZipped = [SSZIP createZipFileAtPath:preferencesZip withContentsOfDirectory:preferences keepParentDirectory:NO withPassword:nil andProgressHandler:^(NSUInteger total, NSUInteger current) {
            // Update progress in the HUD
            dispatch_async(dispatch_get_main_queue(), ^{
                hud.detailTextLabel.text = [NSString stringWithFormat:@"%ld/%ld", total, current];
            });
        }];
        
        BOOL isLibraryZipped = [SSZIP createZipFileAtPath:LibraryZip withContentsOfDirectory:Library keepParentDirectory:NO withPassword:nil andProgressHandler:^(NSUInteger total, NSUInteger current) {
            // Update progress in the HUD
            dispatch_async(dispatch_get_main_queue(), ^{
                hud.detailTextLabel.text = [NSString stringWithFormat:@"%ld/%ld", total, current];
            });
        }];
        
        // Check if all zips were successful
        if (isDocumentZipped && isLibraryZipped && isPreferencesZipped) {
            // Create the backup zip file
            BOOL success = [SSZIP createZipFileAtPath:BackupZip withFilesAtPaths:@[DocumentsZip, LibraryZip, preferencesZip]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Dismiss HUD and handle success/failure
                [hud dismiss];
                
                if (success) {
                    NSURL *zipURL = [NSURL fileURLWithPath:BackupZip];
                    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURL:zipURL inMode:UIDocumentPickerModeExportToService];
                    [self presentViewController:documentPicker animated:YES completion:nil];
                } else {
                    [self showAlertWithTitle:@"Failed" message:@"failed to zip. sorry 🥺"];
                }
            });
        } else {
            // Handle failure to zip individual directories
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud dismiss];
                [self showAlertWithTitle:@"Failed" message:@"failed to zip directories. sorry 🥺"];
            });
        }
    });
}

// Check if directories exist
- (BOOL)directoriesExist:(NSArray<NSString *> *)directories {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *directory in directories) {
        if (![fileManager fileExistsAtPath:directory]) {
            return NO;
        }
    }
    return YES;
}

// Method to restore the Documents and Library directories from a zip file
- (void)restoreBackup {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.zip-archive"] inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

// Document picker delegate method to handle file selection for restore
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *zipFileURL = urls.firstObject;
    if (zipFileURL) {
        [self restoreFromZipAtURL:zipFileURL];
    }
}

// Restore from the selected zip file
- (void)restoreFromZipAtURL:(NSURL *)zipFileURL {
    NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TTKHTTP"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    if (![fileManager fileExistsAtPath:tempDirectory]) {
        BOOL isCreated = [fileManager createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (!isCreated) {
            NSLog(@"Failed to create temp directory: %@", error.localizedDescription);
            [self showAlertWithTitle:@"Error" message:@"failed to create temporary directory"];
            return;
        }
    }

    NSLog(@"Zip File URL: %@", zipFileURL);
    
    JGProgressHUD *hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    hud.textLabel.text = @"Restoring...";
    [hud showInView:self.view];

    Class SSZIP = objc_getClass("SSZipArchive");
    NSLog(@"Starting to Zip now");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        BOOL isMainZipUnzipped = [SSZIP unzipFileAtPath:zipFileURL.path toDestination:tempDirectory overwrite:YES password:nil error:&error];
        if (!isMainZipUnzipped || error) {
            NSLog(@"Error Unzipping Main File: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud dismiss];
                [self showAlertWithTitle:@"Error" message:@"failed to unzip the main file"];
            });
            return;
        }
       
        NSString *MainDocumentsDIR = [home stringByAppendingPathComponent:@"Documents"];
        NSString *LibraryDIR = [home stringByAppendingPathComponent:@"Library"];
        NSString *PreferencesDIR = [LibraryDIR stringByAppendingPathComponent:@"Preferences"];
        
        BOOL isDocumentUnzipped = [SSZIP unzipFileAtPath:[tempDirectory stringByAppendingPathComponent:@"Documents.zip"] toDestination:MainDocumentsDIR];
		  
		  NSLog(@"Documents Directory unzipped to %@: %d", MainDocumentsDIR, isDocumentUnzipped);
		  
        BOOL isPreferencesUnzipped = [SSZIP unzipFileAtPath:[tempDirectory stringByAppendingPathComponent:@"Preferences.zip"] toDestination:PreferencesDIR];
		  
		  NSLog(@"Preferences Directory unzipped to %@: %d", PreferencesDIR, isPreferencesUnzipped);
		  
        BOOL isLibraryUnzipped = [SSZIP unzipFileAtPath:[tempDirectory stringByAppendingPathComponent:@"Library.zip"] toDestination:[tempDirectory stringByAppendingPathComponent:@"LibraryTMP"]];

		  NSLog(@"Library Directory unzipped to %@: %d", [tempDirectory stringByAppendingPathComponent:@"LibraryTMP"] , isLibraryUnzipped);
        if (!isDocumentUnzipped || !isPreferencesUnzipped || !isLibraryUnzipped) {
			  NSString *failedFile = @"";
			  if (!isDocumentUnzipped) {
				  failedFile = @"Documents.zip";
			  } else if (!isPreferencesUnzipped) {
				  failedFile = @"Preferences.zip";
			  } else if (!isLibraryUnzipped) {
				  failedFile = @"Library.zip";
			  }
			  
			  dispatch_async(dispatch_get_main_queue(), ^{
				  [hud dismiss];
				  NSString *errorMessage = [NSString stringWithFormat:@"Failed to unzip file: %@", failedFile];
				  [self showAlertWithTitle:@"Error" message:errorMessage];
			  });
			  return;
		  }

        NSArray *items = [fileManager contentsOfDirectoryAtPath:[tempDirectory stringByAppendingPathComponent:@"LibraryTMP"] error:&error];
        if (error) {
            NSLog(@"Failed to get contents of directory: %@", error.localizedDescription);
        }
        NSLog(@"Items: %@", items);
        for (NSString *item in items) {
			   NSLog(@"Item: %@", item);
            if ([item isEqualToString:@"Preferences"] || [item isEqualToString:@"SyncedPreferences"]) {
                continue;
            }
				NSString *a = [LibraryDIR stringByAppendingPathComponent:item];
            if ([fileManager fileExistsAtPath:a]) {
					BOOL isFileRemoved = [fileManager removeItemAtPath:a error:nil];
					if (isFileRemoved) {
						NSLog(@"Removed : %@", a);
					} else {
						NSLog(@"Failed To Remove : %@", a);
					}
            }
            NSString *sourcePath = [[tempDirectory stringByAppendingPathComponent:@"LibraryTMP"] stringByAppendingPathComponent:item];
            NSString *destinationPath = [LibraryDIR stringByAppendingPathComponent:item];
            
            BOOL success = [fileManager moveItemAtPath:sourcePath toPath:destinationPath error:&error];
            if (!success || error) {
                NSLog(@"Failed to move item %@: %@", item, error.localizedDescription);
            } else {
                NSLog(@"Moved item %@ to %@", item, LibraryDIR);
            }
        }

        [[NSFileManager defaultManager] removeItemAtPath:tempDirectory error:nil];
     
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud dismiss];
            [self showAlertWithTitle:@"Success" message:@"restored successfully🤑. restart the app"];
            NSLog(@"Restore completed successfully.");
        });
    });
}

// Present an alert with a title and message
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIViewController *rootController = [[UIApplication sharedApplication] delegate].window.rootViewController;
            if (rootController) {
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[ViewController new]];
                [rootController presentViewController:navigationController animated:YES completion:nil];
            }
        });
    }];
}
