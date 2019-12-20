﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http.Extensions;
using Microsoft.Identity.Client;
using System.Security.Claims;
using WebApp_OpenIDConnect_DotNet.Models;
using System.Net.Http.Headers;
using System.Net.Http;
using System.Net;
using Microsoft.Extensions.Options;

namespace WebApp_OpenIDConnect_DotNet.Controllers
{
    public class HomeController : Controller
    {
        readonly AzureAdB2COptions AzureAdB2COptions;
        public HomeController(IOptions<AzureAdB2COptions> azureAdB2COptions)
        {
            AzureAdB2COptions = azureAdB2COptions.Value;
        }

        public IActionResult Index()
        {
            // shoud really figure out how to do this at startup/config
            string url = HttpContext.Request.GetEncodedUrl();
            if ( !Request.IsHttps  )
            {
                url = url.Replace("http://", "https://");
                return new RedirectResult(url);
            }
            return View();
        }

        [Authorize]
        public IActionResult About()
        {
            ViewData["Message"] = string.Format("Claims available for the user {0}", (User.FindFirst("name")?.Value));
            return View();
        }

        [Authorize]
        public async Task<IActionResult> Api()
        {
            string responseString;
            try
            {
                // Retrieve the token with the specified scopes
                var scope = AzureAdB2COptions.ApiScopes.Split(' ');
                string signedInUserID = HttpContext.User.FindFirst(ClaimTypes.NameIdentifier).Value;

                IConfidentialClientApplication cca =
                ConfidentialClientApplicationBuilder.Create(AzureAdB2COptions.ClientId)
                    .WithLogging(MyLoggingMethod, LogLevel.Verbose, enablePiiLogging: false, enableDefaultPlatformLogging: true)
                    .WithRedirectUri(AzureAdB2COptions.RedirectUri)
                    .WithClientSecret(AzureAdB2COptions.ClientSecret)
                    .WithB2CAuthority(AzureAdB2COptions.Authority)
                    .Build();
                new MSALStaticCache(signedInUserID, this.HttpContext).EnablePersistence(cca.UserTokenCache);

                var accounts = await cca.GetAccountsAsync();
                AuthenticationResult result = await cca.AcquireTokenSilent(scope, accounts.FirstOrDefault())
                    .ExecuteAsync();

                if ( result.AccessToken == null )
                {
                    ViewData["Title"] = "JWT Token Problem"; 
                    ViewData["Payload"] = "The current user session does not have a valid access_token. Most likely the scopes do not match the App registration.";
                    return View();
                }
                HttpClient client = new HttpClient();
                HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Get, AzureAdB2COptions.ApiUrl);

                // Add token to the Authorization header and make the request
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", result.AccessToken );
                HttpResponseMessage response = await client.SendAsync(request);

                // Handle the response
                switch (response.StatusCode)
                {
                    case HttpStatusCode.OK:
                        responseString = await response.Content.ReadAsStringAsync();
                        break;
                    case HttpStatusCode.Unauthorized:
                        responseString = $"Please sign in again. {response.ReasonPhrase}";
                        break;
                    default:
                        responseString = $"Error calling API. StatusCode=${response.StatusCode}";
                        break;
                }
                client.Dispose();
            }
            catch (MsalUiRequiredException ex)
            {
                responseString = $"Session has expired. Please sign in again. {ex.Message}";
            }
            catch (Exception ex)
            {
                responseString = $"Error calling API: {ex.Message}";
            }

            ViewData["Payload"] = $"{responseString}";            
            return View();
        }

        public IActionResult Error(string message)
        {
            ViewBag.Message = message;
            return View();
        }
        void MyLoggingMethod(LogLevel level, string message, bool containsPii)
        {
            if (containsPii)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"MSAL {level} {containsPii} {message}");
                Console.ResetColor();
            }
            else
            {
                Console.WriteLine($"MSAL {level} {containsPii} {message}");
            }
        }
    } // cls
} // ns
