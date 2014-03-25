//
//  ProjectTests.m
//  ProjectTests
//
//  Created by Fabio Pelosin on 12/11/13.
//  Copyright (c) 2013 Fabio Pelosin. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <IFBKCampground/IFBKAccountsController.h>
#import "NSError+IFBKCampground.h"

/*
 * This class includes the private header because the callbacks are a bit 
 * nested. No the cleanest solution but for now it will do.
 */
#import <IFBKCampground/IFBKAccountsController+Private.h>

SPEC_BEGIN(IFBKAccountsControllerTests)

describe(@"IFBKAccountsController", ^{

    __block IFBKAccountsController *sut;

    beforeEach(^{
        IFBKLPAccount *account1 = [IFBKLPAccount modelWithDictionary:@{@"id": @"1",
                                                                       @"name": @"Account1",
                                                                       @"href": @"account1.campfirenow.com",
                                                                       @"product": @"PRODUCT"}];
        IFBKLPAccount *account2 = [IFBKLPAccount modelWithDictionary:@{@"id": @"2",
                                                                       @"name": @"Account2",
                                                                       @"href": @"account2.campfirenow.com",
                                                                       @"product": @"PRODUCT"}];

        NSArray *accounts = @[account1, account2];
        sut = [IFBKAccountsController newWithAccounts:accounts accessToken:@"ACCESS_TOKE"];
    });

    //--------------------------------------------------------------------------

    context(@"In general", ^{
        it(@"returns the LauchPad accounts", ^{
            [[[sut.launchpadAccounts[0] name] should] equal:@"Account1"];
            [[[sut.launchpadAccounts[1] name] should] equal:@"Account2"];
        });

        it(@"returns the Campfire client for a given LauchPad account", ^{
            IFBKLPAccount *account = sut.launchpadAccounts[0];
            IFBKCampfireClient *client = [sut clientForLaunchpadAccount:account];
            [[client.baseURL should] equal:[NSURL URLWithString:@"account1.campfirenow.com/"]];
        });

        it(@"returns the Campfire client for a given Campfire account", ^{
        });
    });


    //--------------------------------------------------------------------------

    context(@"Delegate", ^{

        __block id delegate;

        beforeEach(^{
            delegate = [KWMock nullMockForProtocol:@protocol(IFBKAccountsControllerDeletage)];
            [sut setDelegate:delegate];
            [sut stub:@selector(clientForLaunchpadAccount:) andReturn:nil];
        });

        it(@"informs the delegate that a new fetch started", ^{
            [[delegate should] receive:@selector(accountsControllerWillStartFetch:) withCount:1];
            [sut fetchInformation];
        });

        xit(@"informs the delegate that all the information has been fetched", ^{
            [[delegate should] receive:@selector(accountsControllerDidCompleteFetch:) withCount:1];
            [sut _willStartFetchOperation];                             // Get Account1
            [sut _willStartFetchOperation];                             // Get Account1 roomList
            [sut _willStartFetchOperation];                             // Get Room 1
            [sut _willStartFetchOperation];                             // Get Room 2
            [sut _campfireClient:nil didGetCurrentAccount:nil];         // Account 1
            [sut _campfireClient:nil didGetRooms:@[] account:nil];      // Account 1 room list
            [sut _campfireClient:nil didGetRoom:nil];                   // Room 1
            [sut _campfireClient:nil didGetRoom:nil];                   // Room 2
        });

        it(@"informs the delegate an error has been encountered", ^{
            [[delegate should] receive:@selector(accountsController:didEncouterFetchError:) withCount:1];
            [sut _campfireClientDidEncounterError:nil response:nil];
        });

        it(@"informs the delegate an error has been encountered only once", ^{
            [[delegate should] receive:@selector(accountsController:didEncouterFetchError:) withCount:1];
            [sut _campfireClientDidEncounterError:nil response:nil];
            [sut _campfireClientDidEncounterError:nil response:nil];
        });

        it(@"doesn't inform the delegate that the information has been fetched if a error is encoutered", ^{
            [[delegate should] receive:@selector(accountsController:didEncouterFetchError:) withCount:1];
            [[delegate should] receive:@selector(accountsControllerDidCompleteFetch:) withCount:0];
            [sut _willStartFetchOperation];                             // Get Account1
            [sut _willStartFetchOperation];                             // Get Account2
            [sut _campfireClientDidEncounterError:nil response:nil];    // Account 1 Failure
            [sut _campfireClient:nil didGetCurrentAccount:nil];         // Account 2
        });

        it(@"informs the delegate that the error can be recovered by re-trying later", ^{
            KWCaptureSpy *spy = [delegate captureArgument:@selector(accountsController:didEncouterFetchError:) atIndex:1];
            NSError *underlyingError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
            [sut _campfireClientDidEncounterError:underlyingError response:nil];
            NSError *error = spy.argument;
            [[theValue([error shouldRecoverByReauthorizing]) should] beFalse];
            [[theValue([error shouldRecoverByReestablishingInternetConnection]) should] beTrue];
        });

        it(@"informs the delegate that the error can be recovered by re-authorizing", ^{
            KWCaptureSpy *spy = [delegate captureArgument:@selector(accountsController:didEncouterFetchError:) atIndex:1];
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:401 HTTPVersion:nil headerFields:nil];
            [sut _campfireClientDidEncounterError:nil response:response];
            NSError *error = spy.argument;
            [[theValue([error shouldRecoverByReauthorizing]) should] beTrue];
            [[theValue([error shouldRecoverByReestablishingInternetConnection]) should] beFalse];
        });
    });



    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------

//    context(@"Fetching Information", ^{
//        __block IFBKCampfireClient *campfireClientMock;
//        __block IFBKCFAccount *account1;
//        __block IFBKCFAccount *account2;
//        __block KWCaptureSpy *campfireAccount1SucessBlockSpy;
//        __block KWCaptureSpy *campfireAccount2SucessBlockSpy;
//        __block KWCaptureSpy *getRoomsSuccessSpy;
//        __block KWCaptureSpy *getRoomsForIDSuccessSpy;
//
//
//        beforeEach(^{
//            campfireClientMock = [IFBKCampfireClient mock];
//            [sut stub:@selector(clientForLaunchpadAccount:) andReturn:campfireClientMock];
//            account1 = [IFBKCFAccount modelWithDictionary:@{@"id": @1, @"name": @"Account1", @"created_at": @"2013/01/01 00:00:00 +0000"}];
//            account2 = [IFBKCFAccount modelWithDictionary:@{@"id": @2, @"name": @"Account2", @"created_at": @"2013/01/02 00:00:00 +0000"}];
//
//            campfireAccount1SucessBlockSpy = [campfireClientMock captureArgument:@selector(getCurrentAccount:failure:) atIndex:0];
//            campfireAccount2SucessBlockSpy = [campfireClientMock captureArgument:@selector(getCurrentAccount:failure:) atIndex:0];
//            getRoomsSuccessSpy = [campfireClientMock captureArgument:@selector(getRooms:failure:) atIndex:0];
//            getRoomsForIDSuccessSpy = [campfireClientMock captureArgument:@selector(getRoomForId:success:failure:) atIndex:1];
//
//            [sut fetchInformation];
//
//            void (^campfireAccountSucessBlock)(IFBKCFAccount *account);
//            campfireAccountSucessBlock = campfireAccount1SucessBlockSpy.argument;
//            campfireAccountSucessBlock(account1);
//            campfireAccountSucessBlock = campfireAccount2SucessBlockSpy.argument;
//            campfireAccountSucessBlock(account2);
//
//            IFBKCFRoom *room1 = [IFBKCFRoom modelWithDictionary:@{@"id": @11, @"name": @"Account1Room1", @"created_at": @"2013/01/01 00:00:00 +0000"}];
//            IFBKCFRoom *room2 = [IFBKCFRoom modelWithDictionary:@{@"id": @12, @"name": @"Account1Room2", @"created_at": @"2013/01/02 00:00:00 +0000"}];
//            void (^getRoomsSuccess)(NSArray *array) = getRoomsSuccessSpy.argument;
//            getRoomsSuccess(@[room2, room1]);
//
//            IFBKCFRoom *room1WithUSers = [IFBKCFRoom modelWithDictionary:@{
//                                                                           @"id": @11,
//                                                                           @"name": @"Account1Room1",
//                                                                           @"created_at": @"2013/01/01 00:00:00 +0000",
//                                                                           @"users": @[@{@"name": @"USER_1"}, @{@"name": @"USER_2"}],
//                                                                           }];
//            void (^getRoomsForIDSuccess)(IFBKCFRoom *room) = getRoomsForIDSuccessSpy.argument;
//            getRoomsForIDSuccess(room1WithUSers);
//        });
//
//        it(@"returns the accounts sorting them by creation date", ^{
//            NSArray *accountNames = [[sut campfireAccounts] valueForKey:@"name"];
//            [[accountNames should] equal:@[@"Account1", @"Account2"]];
//        });
//
//        it(@"returns the identifiers of the rooms associated with a given account", ^{
//            NSArray *roomIdentifiers = [sut roomIdentifiersForcampfireAccount:account1];
//            [[roomIdentifiers should] equal:@[@12, @11]];
//        });

//        it(@"stores the room by identifier", ^{
//            NSDictionary *roomsByID = [sut roomsByID];
//            [sut stub:@selector(roomsByID) andReturn:@{}];
//            NSArray *account1RoomNames = [[sut roomsForcampfireAccount:account1] valueForKey:@"name"];
//            [[account1RoomNames should] equal:@[@"Account1Room1", @"Account1Room2"]];
//        });

//        it(@"returns the rooms sorting them by creation date", ^{
//            [sut stub:@selector(roomsByID) andReturn:@{}];
//            NSArray *account1RoomNames = [[sut roomsForcampfireAccount:account1] valueForKey:@"name"];
//            [[account1RoomNames should] equal:@[@"Account1Room1", @"Account1Room2"]];
//        });

//        it(@"returns the users sorting them by name", ^{
//            IFBKCFRoom *room = [sut roomsForcampfireAccount:account1].firstObject;
//            NSArray *account1Room1UserNames = [[sut usersForcampfireRoom:room] valueForKey:@"name"];
//            [[account1Room1UserNames should] equal:@[@"USER_1", @"USER_1"]];
//        });
//    });


    //--------------------------------------------------------------------------

    context(@"Accessing the fetched information", ^{
        it(@"campfireAccountForRoom", ^{
        });

        it(@"campfireAccountForRoom", ^{
        });
    });
});

SPEC_END
