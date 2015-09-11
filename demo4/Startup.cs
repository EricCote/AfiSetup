using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(demo4.Startup))]
namespace demo4
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
