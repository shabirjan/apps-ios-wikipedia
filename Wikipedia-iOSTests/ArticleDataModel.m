//
//  TestArticleDataModel.m
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 11/26/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Article.h"
#import "DiscoveryContext.h"
#import "DataContextSingleton.h"
#import "Section.h"
#import "History.h"
#import "Saved.h"
#import "DiscoveryMethod.h"
#import "Image.h"

@interface TestArticleDataModel : XCTestCase{

}

@property (strong, nonatomic) NSManagedObjectContext *dataContext;

@end

@implementation TestArticleDataModel

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


// Named with %% to ensure order of execution

- (void)test_01_CreateArticle
{
    NSError *error = nil;

    DataContextSingleton *dataContext = [DataContextSingleton sharedInstance];
    Article *article = [NSEntityDescription insertNewObjectForEntityForName:@"Article" inManagedObjectContext:dataContext];

    article.dateCreated = [NSDate date];
    article.lastScrollLocation = @123.0f;
    article.title = @"This is a sample title.";

    // Add history for article
    History *history0 = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:dataContext];
    history0.dateVisited = [NSDate date];
    [article addHistoryObject:history0];

    History *history1 = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:dataContext];
    history1.dateVisited = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24];
    [article addHistoryObject:history1];

    // Add prefix context for article
    DiscoveryContext *preContext = [NSEntityDescription insertNewObjectForEntityForName:@"DiscoveryContext" inManagedObjectContext:dataContext];
    preContext.isPrefix = @YES;
    preContext.text = @"Some potato chip pre-context.";

    // Add postfix context for article
    DiscoveryContext *postContext = [NSEntityDescription insertNewObjectForEntityForName:@"DiscoveryContext" inManagedObjectContext:dataContext];
    postContext.isPrefix = @YES;
    postContext.text = @"Some potato chip post-context.";

    preContext.history = history0;
    postContext.history = history0;

    // Add sections for article
    Section *section0 = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:dataContext];
    section0.index = @0;
    section0.title = @"Potato chip section 0 title";
    section0.html = @"<b>Potato Chips section 0 html!</b>";
    section0.dateRetrieved = [NSDate date];

    Section *section1 = [NSEntityDescription insertNewObjectForEntityForName:@"Section" inManagedObjectContext:dataContext];
    section1.index = @1;
    section1.title = @"Potato chip section 1 title";
    section1.html = @"<b>Potato Chips section 1 html!</b>";
    section1.dateRetrieved = [NSDate date];

    article.section = [NSSet setWithObjects:section0, section1, nil];

    // Add saved for article
    Saved *saved0 = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:dataContext];
    saved0.dateSaved = [NSDate date];
    [article addSavedObject:saved0];
    
    Saved *saved1 = [NSEntityDescription insertNewObjectForEntityForName:@"Saved" inManagedObjectContext:dataContext];
    saved1.dateSaved = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24];
    [article addSavedObject:saved1];
    
    // Add discovery method for article

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"DiscoveryMethod"
                                              inManagedObjectContext: dataContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", @"random"];
    [fetchRequest setPredicate:pred];
    
    error = nil;
    NSArray *methods = [dataContext executeFetchRequest:fetchRequest error:&error];
    XCTAssert(error == nil, @"Could not fetch article.");

    if (methods.count == 1) {
        DiscoveryMethod *method = (DiscoveryMethod *)methods[0];
        NSLog(@"%@", method.name);
        history0.discoveryMethod = method;
history1.discoveryMethod = method;
    }

    // Create test image
    CGRect rect = CGRectMake(0, 0, 10, 10);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [[UIColor redColor] setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Get image data
    CGDataProviderRef provider = CGImageGetDataProvider(image.CGImage);
    NSData *imageData = (id)CFBridgingRelease(CGDataProviderCopyData(provider));

    Image *thumb = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:dataContext];
    thumb.data = imageData;
    thumb.fileName = @"thisThumb.jpg";
    thumb.extension = @"jpg";
    thumb.imageDescription = @"Sample thumb description";
    thumb.dateRetrieved = [NSDate date];
    thumb.width = @100.0f;
    thumb.height = @200.0f;
    thumb.sourceUrl = @"http://www.this_is_a_placeholder.org/image.jpg";
    article.thumbnailImage = thumb;

    article.site = (Site *)[self getEntityForName: @"Site" withPredicate:[NSPredicate predicateWithFormat:@"name == %@", @"wikipedia.org"]];
    
    article.domain = (Domain *)[self getEntityForName: @"Domain" withPredicate:[NSPredicate predicateWithFormat:@"name == %@", @"en"]];

    // Save the article!
    error = nil;
    [dataContext save:&error];
    XCTAssert(error == nil, @"Could not save article.");
}

//TODO: Add tests here to confirm tables other than "Article" contain data...

- (void)test_02_DeleteArticles
{
    NSError *error = nil;
    DataContextSingleton *dataContext = [DataContextSingleton sharedInstance];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Article"
                                              inManagedObjectContext: dataContext];
    [fetchRequest setEntity:entity];
    
    //NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", @"random"];
    //[fetchRequest setPredicate:pred];

    error = nil;
    NSArray *articles = [dataContext executeFetchRequest:fetchRequest error:&error];
    XCTAssert(error == nil, @"Could not retrieve articles to be deleted.");
    for (Article *article in articles) {
        [dataContext deleteObject:article];
    }
    
    error = nil;
    [dataContext save:&error];
    XCTAssert(error == nil, @"Could not delete articles.");
}

- (void)test_03_ConfirmAllArticleDataWasDeleted
{
    NSError *error = nil;
    DataContextSingleton *dataContext = [DataContextSingleton sharedInstance];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Article"
                                              inManagedObjectContext: dataContext];
    [fetchRequest setEntity:entity];
    
    //NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", @"random"];
    //[fetchRequest setPredicate:pred];
    
    error = nil;
    NSArray *articles = [dataContext executeFetchRequest:fetchRequest error:&error];
    XCTAssert(error == nil, @"Could determine how many articles remain.");
    XCTAssert(articles.count == 0, @"Articles still exist but should not.");
}

- (void)test_04_ConfirmAllImageDataWasDeleted
{
    NSError *error = nil;
    DataContextSingleton *dataContext = [DataContextSingleton sharedInstance];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Image"
                                              inManagedObjectContext: dataContext];
    [fetchRequest setEntity:entity];
    
    //NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", @"random"];
    //[fetchRequest setPredicate:pred];
    
    error = nil;
    NSArray *images = [dataContext executeFetchRequest:fetchRequest error:&error];
    XCTAssert(error == nil, @"Could determine how many images remain.");
    
    // Note: this Assert will probably fail. Left in place as a reminder to implement some way to limit
    // number of images! Maybe when app starts remove all images older than a certain date, or remove
    // any in excess of a size threshold?
    XCTAssert(images.count == 0, @"Images still exist but should not.");
}

- (void)test_05_EnsureDiscoveryMethodsNotDeleted
{
    // Confirm discoveryMethods table records for “search", "link", and "random” still exist.

    NSError *error = nil;
    DataContextSingleton *dataContext = [DataContextSingleton sharedInstance];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName : @"DiscoveryMethod"
                                              inManagedObjectContext : dataContext];
    [fetchRequest setEntity:entity];

    error = nil;
    NSArray *existingMethods = [dataContext executeFetchRequest:fetchRequest error:&error];
    
    XCTAssert(error == nil, @"Could determine how many discovery methods remain.");
    XCTAssert(existingMethods.count == 3, @"Expected discovery methods not found");
}

-(NSManagedObject *)getEntityForName:(NSString *)entityName withPredicate:(NSPredicate *)predicate
{
    DataContextSingleton *dataContext = [DataContextSingleton sharedInstance];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: dataContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];

    error = nil;
    NSArray *methods = [dataContext executeFetchRequest:fetchRequest error:&error];
    //XCTAssert(error == nil, @"Could not fetch article.");

    if (methods.count == 1) {
        NSManagedObject *method = (NSManagedObject *)methods[0];
        return method;
    }else{
        return nil;
    }
}

@end