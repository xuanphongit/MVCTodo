using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using System.Security.Claims;
using Todo.Model;

namespace Todo.Controllers
{
    public class AccountController : Controller
    {
        private readonly IConfiguration _configuration;

        public AccountController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpGet]
        public IActionResult Login()
        {
            if (User.Identity?.IsAuthenticated == true)
            {
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Login(User model)
        {
            Console.WriteLine($"Login attempt - Username: {model.Username}, Password length: {(model.Password?.Length ?? 0)}");

            if (string.IsNullOrEmpty(model.Username) || string.IsNullOrEmpty(model.Password))
            {
                Console.WriteLine("Login failed - Empty username or password");
                ModelState.AddModelError("", "Vui lòng nhập đầy đủ thông tin");
                return View(model);
            }

            if (IsValidUser(model))
            {
                Console.WriteLine("User validation successful");

                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.Name, model.Username),
                    new Claim(ClaimTypes.Role, "User"),
                };

                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                var principal = new ClaimsPrincipal(claimsIdentity);

                var authProperties = new AuthenticationProperties
                {
                    IsPersistent = true,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddHours(1),
                    AllowRefresh = true
                };

                try
                {
                    await HttpContext.SignInAsync(
                        CookieAuthenticationDefaults.AuthenticationScheme,
                        principal,
                        authProperties);

                    Console.WriteLine("Authentication successful - Redirecting to Home/Index");
                    return RedirectToAction("Index", "Home");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Authentication error: {ex.Message}");
                    Console.WriteLine($"Stack trace: {ex.StackTrace}");
                    ModelState.AddModelError("", "Có lỗi xảy ra trong quá trình đăng nhập");
                    return View(model);
                }
            }

            Console.WriteLine("Invalid credentials - Username or password incorrect");
            ModelState.AddModelError("", "Tên đăng nhập hoặc mật khẩu không đúng");
            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("Login");
        }

        private bool IsValidUser(User user)
        {
            var configUsername = _configuration["Authentication:DefaultCredentials:Username"];
            var configPassword = _configuration["Authentication:DefaultCredentials:Password"];
            
            var isValid = user.Username == configUsername && user.Password == configPassword;
            Console.WriteLine($"IsValidUser check - Username: {user.Username}, IsValid: {isValid}");
            return isValid;
        }
    }
} 