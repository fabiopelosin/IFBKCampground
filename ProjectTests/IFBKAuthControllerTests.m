//
//  ProjectTests.m
//  ProjectTests
//
//  Created by Fabio Pelosin on 12/11/13.
//  Copyright (c) 2013 Fabio Pelosin. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <IFBKCampground/IFBKCampground.h>

SPEC_BEGIN(IFBKAuthControllerTests)

describe(@"IFBKAuthController", ^{

    __block IFBKAuthController *sut;

    beforeEach(^{
        sut = [IFBKAuthController newWithClientID:@"CLIENT_ID" clientSecret:@"CLIENT_SECRET" redirectURI:@"REDIRECT_URI"];
    });

    context(@"-authorizeWithSuccess:failure:", ^{
        it(@"attempts authorization with the access token", ^{
            [sut setAccessToken:@"ACCESS_TOKEN"];
            [sut setExpirationDate:[NSDate dateWithTimeIntervalSinceNow:9999]];
            KWCaptureSpy *spy = [IFBKLaunchpadClient captureArgument:@selector(getAuthorizationData:failure:) atIndex:0];

            [sut authorizeWithSuccess:^(IFBKLPAuthorizationData *authData) {
                [[authData shouldNot] beNil];
            } failure:^(NSError *authError) {
            }];

            // Accept the acess token
            void (^LaunchpadClienSucessBlock)(IFBKLPAuthorizationData *authData) = spy.argument;
            LaunchpadClienSucessBlock([IFBKLPAuthorizationData mock]);
        });

        it(@"attempts authorization with the refresh token if no access token has been set", ^{
            [sut setRefreshToken:@"REFRESH_TOKEN"];

            KWCaptureSpy *refreshSpy = [IFBKLaunchpadClient captureArgument:@selector(refreshAccessTokenWithRefreshToken:success:failure:) atIndex:1];
            KWCaptureSpy *getAuthorizationSpy = [IFBKLaunchpadClient captureArgument:@selector(getAuthorizationData:failure:) atIndex:0];
            [sut authorizeWithSuccess:^(IFBKLPAuthorizationData *authData) {
                [[authData shouldNot] beNil];
            } failure:^(NSError *authError) {
            }];

            // Returns a new access token
            void (^refreshSucessBlock)(NSString *accessToken, NSDate *expiresAt) = refreshSpy.argument;
            refreshSucessBlock(@"ACCESS_TOKEN", [NSDate dateWithTimeIntervalSinceNow:9999]);

            // Accept the access token
            void (^getAuthorizationSucessBlock)(IFBKLPAuthorizationData *authData) = getAuthorizationSpy.argument;
            getAuthorizationSucessBlock([IFBKLPAuthorizationData mock]);
        });

        it(@"refreshes an expired access token", ^{
            [sut setAccessToken:@"OLD_ACCESS_TOKEN"];
            [sut setExpirationDate:[NSDate dateWithTimeIntervalSince1970:0]];
            [sut setRefreshToken:@"REFRESH_TOKEN"];

            KWCaptureSpy *refreshSpy = [IFBKLaunchpadClient captureArgument:@selector(refreshAccessTokenWithRefreshToken:success:failure:) atIndex:1];
            [sut authorizeWithSuccess:^(IFBKLPAuthorizationData *authData) {
                [[authData shouldNot] beNil];
            } failure:^(NSError *authError) {
            }];

            // Returns a new access token
            KWCaptureSpy *bearerTokenSpy = [IFBKLaunchpadClient captureArgument:@selector(setBearerToken:) atIndex:0];
            KWCaptureSpy *getAuthorizationSucessSpy = [IFBKLaunchpadClient captureArgument:@selector(getAuthorizationData:failure:) atIndex:0];
            void (^refreshSucessBlock)(NSString *accessToken, NSDate *expiresAt) = refreshSpy.argument;
            NSDate *newExpirationDate = [NSDate dateWithTimeIntervalSinceNow:9999];
            refreshSucessBlock(@"ACCESS_TOKEN", newExpirationDate);

            // Accept the access token
            NSString *newAccessToken = bearerTokenSpy.argument;
            [[newAccessToken should] equal:@"ACCESS_TOKEN"];
            [[sut.accessToken should] equal:@"ACCESS_TOKEN"];
            [[sut.expirationDate should] equal:newExpirationDate];
            void (^getAuthorizationSucessBlock)(IFBKLPAuthorizationData *authData) = getAuthorizationSucessSpy.argument;
            getAuthorizationSucessBlock([IFBKLPAuthorizationData mock]);
        });

        it(@"is robust against refused access tokens", ^{
            [sut setAccessToken:@"INVALID_ACCESS_TOKEN"];
            [sut setExpirationDate:[NSDate dateWithTimeIntervalSinceNow:9999]];
            [sut setRefreshToken:@"REFRESH_TOKEN"];

            KWCaptureSpy *getAuthorizationFailureSpy = [IFBKLaunchpadClient captureArgument:@selector(getAuthorizationData:failure:) atIndex:1];
            KWCaptureSpy *refreshSpy = [IFBKLaunchpadClient captureArgument:@selector(refreshAccessTokenWithRefreshToken:success:failure:) atIndex:1];
            [sut authorizeWithSuccess:^(IFBKLPAuthorizationData *authData) {
                [[authData shouldNot] beNil];
            } failure:^(NSError *authError) {
            }];

            // Refuse access token
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:401 HTTPVersion:nil headerFields:nil];
            void (^getAuthorizationFailureBlock)(NSError *responseError, NSHTTPURLResponse *response) = getAuthorizationFailureSpy.argument;
            getAuthorizationFailureBlock(nil, response);

            // Returns a new access token
            KWCaptureSpy *getAuthorizationSucessSpy = [IFBKLaunchpadClient captureArgument:@selector(getAuthorizationData:failure:) atIndex:0];
            void (^refreshSucessBlock)(NSString *accessToken, NSDate *expiresAt) = refreshSpy.argument;
            refreshSucessBlock(@"ACCESS_TOKEN", [NSDate dateWithTimeIntervalSinceNow:9999]);

            // Accep the access token
            void (^getAuthorizationSucessBlock)(IFBKLPAuthorizationData *authData) = getAuthorizationSucessSpy.argument;
            getAuthorizationSucessBlock([IFBKLPAuthorizationData mock]);
        });

        it(@"fails informing that user authentication is required, if no refresh token has been set", ^{
            [sut authorizeWithSuccess:^(IFBKLPAuthorizationData *authData) {
            } failure:^(NSError *authError) {
                [[theValue([authError shouldRecoverByReauthorizing]) should] beTrue];
            }];
        });

        it(@"fails informing that user authentication is required, if the refresh token has been refused", ^{
            [sut setRefreshToken:@"REFRESH_TOKEN"];
            KWCaptureSpy *refreshSpy = [IFBKLaunchpadClient captureArgument:@selector(refreshAccessTokenWithRefreshToken:success:failure:) atIndex:2];
            [sut authorizeWithSuccess:^(IFBKLPAuthorizationData *authData) {
            } failure:^(NSError *authError) {
                [[theValue([authError shouldRecoverByReauthorizing]) should] beTrue];
            }];

            // Refuse refresh token
            void (^refreshFailureBlock)(NSError *underlyingError, NSHTTPURLResponse *response) = refreshSpy.argument;
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:401 HTTPVersion:nil headerFields:nil];
            refreshFailureBlock(nil, response);
        });

        it(@"fails the authentication informing that the operation should be retried once internet connectivity has been re-established", ^{
        });

        it(@"fails the refresh informing that the operation should be retried once internet connectivity has been re-established", ^{
        });

    });

    context(@"-authorizeWithTemporaryCode:success:failure:", ^{
        it(@"authorizes the user", ^{
            KWCaptureSpy *sucessSpy = [IFBKLaunchpadClient captureArgument:@selector(getAccessTokenForVerificationCode:success:failure:) atIndex:1];
            [sut authorizeWithTemporaryCode:@"TMP_CODE" success:^(IFBKLPAuthorizationData *authData) {
                [[authData shouldNot] beNil];
            } failure:^(NSError *error) {

            }];
            void (^successBlock)(NSString *accessToken, NSString *refreshToken, NSDate *expiresAt) = sucessSpy.argument;
            successBlock(@"AT", @"Tf", [NSDate date]);
        });

        it(@"sets the tokens with a sucessfull authorization", ^{
            KWCaptureSpy *sucessSpy = [IFBKLaunchpadClient captureArgument:@selector(getAccessTokenForVerificationCode:success:failure:) atIndex:1];
            [sut authorizeWithTemporaryCode:@"TMP_CODE" success:^(IFBKLPAuthorizationData *authData) {
            } failure:^(NSError *error) {

            }];
            void (^successBlock)(NSString *accessToken, NSString *refreshToken, NSDate *expiresAt) = sucessSpy.argument;
            NSDate *expiration = [NSDate date];
            successBlock(@"AT", @"RT", expiration);
            [[sut.accessToken should] equal:@"AT"];
            [[sut.refreshToken should] equal:@"RT"];
            [[sut.expirationDate should] equal:expiration];
        });

        it(@"fails informing that user authentication is required, i.e. the temporary code was refused", ^{
            KWCaptureSpy *failureSpy = [IFBKLaunchpadClient captureArgument:@selector(getAccessTokenForVerificationCode:success:failure:) atIndex:2];
            [sut authorizeWithTemporaryCode:@"TMP_CODE" success:^(IFBKLPAuthorizationData *authData) {
            } failure:^(NSError *error) {
                [[theValue([error shouldRecoverByReauthorizing]) should] beTrue];
                [[theValue([error shouldRecoverByReestablishingInternetConnection]) should] beFalse];
            }];
            void (^failureBlock)(NSError *responseError, NSHTTPURLResponse *response) = failureSpy.argument;
            NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:401 HTTPVersion:nil headerFields:nil];
            failureBlock(nil, response);
        });

        it(@"fails informing that the operation should be retried once internet connectivity has been re-established", ^{
            KWCaptureSpy *failureSpy = [IFBKLaunchpadClient captureArgument:@selector(getAccessTokenForVerificationCode:success:failure:) atIndex:2];
            [sut authorizeWithTemporaryCode:@"TMP_CODE" success:^(IFBKLPAuthorizationData *authData) {
            } failure:^(NSError *error) {
                [[theValue([error shouldRecoverByReauthorizing]) should] beFalse];
                [[theValue([error shouldRecoverByReestablishingInternetConnection]) should] beTrue];
            }];
            void (^failureBlock)(NSError *responseError, NSHTTPURLResponse *response) = failureSpy.argument;
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil];
            failureBlock(error, nil);
        });
    });
});

SPEC_END
