//
//  ProjectTests.m
//  ProjectTests
//
//  Created by Fabio Pelosin on 12/11/13.
//  Copyright (c) 2013 Fabio Pelosin. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <IFBKCampground/IFBKRoomController.h>
#import "IFBKCFMessage+Campground.h"

@interface IFBKRoomController (Tests)
- (void)_didReceiveNewMessage:(IFBKCFMessage*)message;
@end

SPEC_BEGIN(IFBKRoomControllerTests)

describe(@"IFBKRoomController", ^{

    __block IFBKRoomController *sut;
    __block id delegate;
    __block IFBKCFMessage *message;

    beforeEach(^{
        sut = [[IFBKRoomController alloc] initWithRoomID:@1 authorizationToken:@"TOKEN"];
        IFBKCFUser *user = [IFBKCFUser mock];
        [[user stubAndReturn:@1] identifier];
        [[user stubAndReturn:@"NAME SURNAME"] name];
        [[sut stubAndReturn:user] user];
        delegate = [KWMock nullMockForProtocol:@protocol(IFBKRoomControllerDelegate)];
        sut.delegate = delegate;
        message = [IFBKCFMessage nullMock];
    });

    ///-------------------------------------------------------------------------

    describe(@"Messages", ^{

        describe(@"doesMessageIncludeMention:", ^{
            it(@"returns that a message includes a mention", ^{
                [[message stubAndReturn:@"Text NAME SURNAME Text"] body];
                BOOL result = [sut doesMessageIncludeMention:message];
                [[theValue(result) should] beTrue];
            });

            it(@"returns that a message doesn't includes a mention", ^{
                [[message stubAndReturn:@"Text Text"] body];
                BOOL result = [sut doesMessageIncludeMention:message];
                [[theValue(result) should] beFalse];
            });

            it(@"performs a case insesitive comparison", ^{
                [[message stubAndReturn:@"Text name surname Text"] body];
                BOOL result = [sut doesMessageIncludeMention:message];
                [[theValue(result) should] beTrue];
            });

            it(@"the name is enought to trigger a mention", ^{
                [[message stubAndReturn:@"Text name Text"] body];
                BOOL result = [sut doesMessageIncludeMention:message];
                [[theValue(result) should] beTrue];
            });
        });
    });

    ///-------------------------------------------------------------------------

    describe(@"Notifications", ^{

        context(@"In general", ^{
            it(@"doesn't post notifications for messages posted by the logged in user", ^{
                [[message stubAndReturn:theValue(YES)] isUserGenerated];
                [[message stubAndReturn:@1] userIdentifier];
                [[delegate shouldNot] receive:@selector(roomController:didReceiveNotificationFormessage:)];
                [sut _didReceiveNewMessage:message];
            });

            it(@"doesn't post notifications for messages which are not user generated", ^{
                [[message stubAndReturn:theValue(NO)] isUserGenerated];
                [[message stubAndReturn:@2] userIdentifier];
                [[delegate shouldNot] receive:@selector(roomController:didReceiveNotificationFormessage:)];
                [sut _didReceiveNewMessage:message];
            });

            it(@"posts notifications for all the new messages by default", ^{
                [[message stubAndReturn:theValue(YES)] isUserGenerated];
                [[message stubAndReturn:@2] userIdentifier];
                [[delegate should] receive:@selector(roomController:didReceiveNotificationFormessage:)];
                [sut _didReceiveNewMessage:message];
            });
        });

        describe(@"notifyOnlyForMentions", ^{
            beforeEach(^{
                sut.notifyOnlyForMentions = YES;
                [[message stubAndReturn:theValue(YES)] isUserGenerated];
                [[message stubAndReturn:@2] userIdentifier];
            });

            it(@"posts notifications for messages including mentions", ^{
                [[message stubAndReturn:@"Text NAME SURNAME Text"] body];
                [[delegate should] receive:@selector(roomController:didReceiveNotificationFormessage:)];
                [sut _didReceiveNewMessage:message];
            });

            it(@"doesn't notifications for messages including mentions", ^{
                [[message stubAndReturn:@"Text Text"] body];
                [[delegate shouldNot] receive:@selector(roomController:didReceiveNotificationFormessage:)];
                [sut _didReceiveNewMessage:message];
            });
        });
    });
});

SPEC_END
