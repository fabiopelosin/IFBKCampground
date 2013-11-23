#import <Foundation/Foundation.h>

/**
 * The error domain of all the errors generated generated by `IFBKCampground`.
 */
extern NSString * const kIFBKCampgroundErrorDomain;

/**
 * The error codes of the `kIFBKCampgroundErrorDomain`.
 */
typedef NS_ENUM(NSInteger, IFBKCampgroundErrorCode) {
    IFBKCampgroundNoInternetConnectivityErrorCode,
    IFBKCampgroundUnknownErrorCode,

    // Authorization Errors
    IFBKCampgroundUserAuthorizationRequiredErrorCode,
    IFBKCampgroundNoAccessTokenErrorCode,
    IFBKCampgroundExpiredAccessTokenErrorCode,
    IFBKCampgroundInvalidAccessTokenErrorCode,
    IFBKCampgroundNoRefreshTokenErrorCode,
    IFBKCampgroundInvalidRefreshTokenErrorCode,
    IFBKCampgroundInvalidTemporaryCodeErrorCode
};

/**
 * Category which provides support for errors generated by `IFBKCampground`.
 *
 * Inspired by the [Consuming Web APIs] talk of Luis Solano (see slide 98).
 * [Consuming Web APIs]: https://speakerdeck.com/lascorbe/luis-solanos-slides-at-nsspain-2013
 */
@interface NSError (IFBKCampground)

/**
 * Convenience method to create a new `IFBKCampground` error.
 *
 * @param errorCode       The code of the error.
 * @param underlyingError The underlying error, if there is one, wrapped by
 *                        this error. The underlying error is stored in the
 *                        `NSUnderlyingErrorKey` key of the user info.
 * @param response        The response, if there is one, which caused this
 *                        error. The response might contain useful information
 *                        to trace the origin of the error.
 */
+ (instancetype)campgroundErrorWithCode:(IFBKCampgroundErrorCode)errorCode underlyingError:(NSError*)underlyingError response:(NSHTTPURLResponse *)response;

/**
 * Wraps an error with the `NSURLDomain` with a new error with either the
 * `IFBKCampgroundNoInternetConnectivityErrorCode` or the
 * `IFBKCampgroundUnknownErrorCode` codes, according to the code of the
 * underlying error.
 *
 * @param underlyingError The underlying error, if there is one, wrapped by
 *                        this error. The underlying error is stored in the
 *                        `NSUnderlyingErrorKey` key of the user info. Must
 *                        have the `NSURLDomain` domain.
 * @param response        The response, if there is one, which caused this
 *                        error. The response might contain useful information
 *                        to trace the origin of the error.
 */
+ (instancetype)campgroundErrorWithNSURLError:(NSError*)underlyingError response:(NSHTTPURLResponse *)response;


+ (instancetype)campgroundErrorWithUnderlayingError:(NSError*)underlyingError response:(NSHTTPURLResponse *)response noAuthorizationErrorCode:(IFBKCampgroundErrorCode)errorCode;


///-----------------------------------------------------------------------------
/// Querying Errors
///-----------------------------------------------------------------------------

/**
 * Returns whether the error is a `IFBKCampground` error.
 */
- (BOOL)isIFBKCampgroundError;

/**
 * Returns whether the error can be recovered by clients asking the user to
 * authorize via OAuth.
 */
- (BOOL)shouldRecoverByReauthorizing;

/**
 * Returns whether the error can be recovered by clients asking the user to
 * restore internet connectivity.
 */
- (BOOL)shouldRecoverByReestablishingInternetConnection;

@end