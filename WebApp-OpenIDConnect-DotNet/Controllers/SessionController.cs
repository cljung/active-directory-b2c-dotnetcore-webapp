using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Microsoft.Extensions.Options;
using Microsoft.AspNetCore.Http.Features.Authentication;
using Microsoft.AspNetCore.Authentication;
using System.IO;
using System.Net;

namespace WebApp_OpenIDConnect_DotNet.Controllers
{
    public class SessionController : Controller
    {
        public SessionController(IOptions<AzureAdB2COptions> b2cOptions)
        {
            AzureAdB2COptions = b2cOptions.Value;
        }

        public AzureAdB2COptions AzureAdB2COptions { get; set; }

        [HttpGet]
        public IActionResult SignIn()
        {
            var redirectUrl = Url.Action(nameof(HomeController.Index), "Home");
            return Challenge(
                new AuthenticationProperties { RedirectUri = redirectUrl },
                OpenIdConnectDefaults.AuthenticationScheme);
        }
        [HttpGet]
        public IActionResult SignUp()
        {
            // if we are being called with the email parameter, then we invoke the B2C sign-up policy with the email querystring
            // so we preset that value
            string email = Request.Query["email"];
            var redirectUrl = Url.Action(nameof(HomeController.Index), "Home");
            var properties = new AuthenticationProperties { RedirectUri = redirectUrl };
            properties.Items[AzureAdB2COptions.PolicyAuthenticationProperty] = AzureAdB2COptions.SignUpPolicyId;
            if (!string.IsNullOrEmpty(email))
            {
                properties.Items.Add("email", email);
            }
            return Challenge(properties, OpenIdConnectDefaults.AuthenticationScheme);
        }

        [HttpGet]
        public IActionResult ResetPassword()
        {
            var redirectUrl = Url.Action(nameof(HomeController.Index), "Home");
            var properties = new AuthenticationProperties { RedirectUri = redirectUrl };

            // reset password when not authenticated means we have pressed the "forget my password" link
            //
            // B2C really return a http body with 
            //  error: access_denied
            //  error_description: AADB2C90118: The user has forgotten their password
            // but that gets eaten in the /signin-oidc handler, which passes it on to here. But since we only can do
            // ResetPassword if we are logged in (link disable otherwise) it must mean that qwe have forgotten our password

            if ( !User.Identity.IsAuthenticated )
            {
                properties.Items[AzureAdB2COptions.PolicyAuthenticationProperty] = AzureAdB2COptions.ForgotPasswordPolicyId;
            }
            else
            {
                properties.Items[AzureAdB2COptions.PolicyAuthenticationProperty] = AzureAdB2COptions.ResetPasswordPolicyId;
            }
            return Challenge(properties, OpenIdConnectDefaults.AuthenticationScheme);
        }

        [HttpGet]
        public IActionResult EditProfile()
        {
            var redirectUrl = Url.Action(nameof(HomeController.Index), "Home");
            var properties = new AuthenticationProperties { RedirectUri = redirectUrl };
            properties.Items[AzureAdB2COptions.PolicyAuthenticationProperty] = AzureAdB2COptions.EditProfilePolicyId;
            return Challenge(properties, OpenIdConnectDefaults.AuthenticationScheme);
        }

        [HttpGet]
        public IActionResult SignOut()
        {
            var callbackUrl = Url.Action(nameof(SignedOut), "Session", values: null, protocol: Request.Scheme);
            return SignOut(new AuthenticationProperties { RedirectUri = callbackUrl },
                CookieAuthenticationDefaults.AuthenticationScheme, OpenIdConnectDefaults.AuthenticationScheme);
        }

        [HttpGet]
        public IActionResult SignedOut()
        {
            // always redirect to home page after sign out. The SignedOut page is of no use
            //if (User.Identity.IsAuthenticated)
            //{
                // Redirect to home page if the user is authenticated.
                return RedirectToAction(nameof(HomeController.Index), "Home");
            //}

            //return View();
        }
    }
}