namespace Todo.Controllers
{
    // Controllers/HomeController.cs
    using Microsoft.AspNetCore.Mvc;
    using Todo.Model;

    public class HomeController : Controller
    {
        private static List<TodoItem> _todos = new List<TodoItem>();
        private static int _nextId = 1;

        public IActionResult Index()
        {
            return View(_todos);
        }

        [HttpGet]
        public IActionResult Create()
        {
            return View();
        }

        [HttpPost]
        public IActionResult Create(string title)
        {
            if (!string.IsNullOrEmpty(title))
            {
                _todos.Add(new TodoItem { Id = _nextId++, Title = title, IsCompleted = false });
            }
            return RedirectToAction("Index");
        }

        [HttpPost]
        public IActionResult Delete(int id)
        {
            var todo = _todos.FirstOrDefault(t => t.Id == id);
            if (todo != null)
            {
                _todos.Remove(todo);
            }
            return RedirectToAction("Index");
        }

        [HttpPost]
        public IActionResult ToggleComplete(int id)
        {
            var todo = _todos.FirstOrDefault(t => t.Id == id);
            if (todo != null)
            {
                todo.IsCompleted = !todo.IsCompleted;
            }
            return RedirectToAction("Index");
        }
    }
}
