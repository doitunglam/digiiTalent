using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using digiiTalentDTO;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;

//using Microsoft.AspNetCore.SignalR;
using Coravel;
using SignalR.Hubs;

namespace digiiTeamW
{
    public class Startup
    {
        public IConfiguration _Configuration { get;}
        public Startup(IConfiguration configuration)
        {
            _Configuration = configuration;
        }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllersWithViews();
            services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(options =>
            {
                options.Cookie.Name = "digiiTeamw";
                options.ExpireTimeSpan = TimeSpan.FromDays(30);
                options.LoginPath = "/Login";
            });
            services.ConfigureApplicationCookie(options =>
            {
                options.Cookie.Name = "digiiTeamw";
                options.ExpireTimeSpan = TimeSpan.FromDays(30);
                options.SlidingExpiration = true;
            });
            services.AddSession(options =>
            {
                options.IdleTimeout = TimeSpan.FromDays(30);
                options.Cookie.HttpOnly = true;
                options.Cookie.IsEssential = true;
            });

            services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_3_0);
            services.AddQueue();
            services.AddSignalR();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                app.UseHsts();
            }
            app.UseHttpsRedirection();
            app.UseStaticFiles();
            
            app.UseCookiePolicy();
            app.UseSession();
            //app.UseSignalR(routes =>
            //{
            //    routes.MapHub<ProgressHub>("/ProgressHub");
            //});

            app.UseRouting();

            app.UseAuthentication();// Must be after UseRouting()
            app.UseAuthorization();// Must be after UseAuthentication()

            var cookiePolicyOptions = new CookiePolicyOptions
            {
                MinimumSameSitePolicy = Microsoft.AspNetCore.Http.SameSiteMode.Strict,
            };
            app.UseCookiePolicy(cookiePolicyOptions);

            List<string> lstControl = new List<string>();

            #region Control Name
            lstControl.Add("teamw_active");
            lstControl.Add("hrs");
            lstControl.Add("hrs_encrypt");
            lstControl.Add("hrs_LAY_DSDanhGiaTongHop");
            
            lstControl.Add("login");
            lstControl.Add("logout");
            
            lstControl.Add("_test");
            lstControl.Add("Progress");
            lstControl.Add("_canh_bao_quyen");
            
            lstControl.Add("bao-cao");
            lstControl.Add("tao-dot-phan-tich");
            lstControl.Add("phan-tich-9-hop");
            lstControl.Add("quy-uoc");
            lstControl.Add("mo-hinh-9-hop");

            lstControl.Add("admin-nhom-quyen");
            lstControl.Add("admin-phan-quyen");
            lstControl.Add("admin-nguoi-dung");

            lstControl.Add("co-cau-to-chuc");
            lstControl.Add("co-cau-chuc-danh");
            lstControl.Add("co-cau-nhan-su");
            lstControl.Add("co-cau-nhom-cap");

            lstControl.Add("pop-tao-dot-phan-tich");
            lstControl.Add("pop-phan-tich-9-hop");
            lstControl.Add("pop-quy-uoc");
            lstControl.Add("pop-mo-hinh-9-hop");

            lstControl.Add("pop-admin-nhom-quyen");
            lstControl.Add("pop-admin-phan-quyen");
            lstControl.Add("pop-admin-nguoi-dung");

            lstControl.Add("pop-co-cau-to-chuc");
            lstControl.Add("pop-co-cau-chuc-danh");
            lstControl.Add("pop-co-cau-nhan-su");
            lstControl.Add("pop-co-cau-nhom-cap");
            
            lstControl.Add("bao_cao_json");
            lstControl.Add("thong_bao_json");
            
            lstControl.Add("tao_dot_phan_tich_json");
            lstControl.Add("phan_tich_9_hop_json");
            lstControl.Add("quy_uoc_json");
            lstControl.Add("mo_hinh_9_hop_json");

            lstControl.Add("admin_nhom_quyen_json");
            lstControl.Add("admin_phan_quyen_json");
            lstControl.Add("admin_nguoi_dung_json");

            lstControl.Add("co_cau_to_chuc_json");
            lstControl.Add("co_cau_chuc_danh_json");
            lstControl.Add("co_cau_nhan_su_json");
            lstControl.Add("co_cau_nhom_cap_json");

            lstControl.Add("co_cau_to_chuc_JsonDDL");
            lstControl.Add("co_cau_to_chuc_con_JsonDDL");
            lstControl.Add("co_cau_nhom_cap_JsonDDL");
            lstControl.Add("nhan_su_search_JsonDDL");
            lstControl.Add("nhan_su_search_AllChucDanh_JsonDDL");
            lstControl.Add("nhan_su_searchFull_JsonDDL");
            lstControl.Add("nhan_su_searchAdvance_JsonDDL");
            lstControl.Add("chuc_danh_search_JsonDDL"); 
            lstControl.Add("chuc_danh_nhan_su_JsonDDL");
            
            lstControl.Add("DUYET_MucTieuJson");
            lstControl.Add("HUY_DUYET_MucTieuJson");
            lstControl.Add("TRA_VE_MucTieuJson");
            lstControl.Add("KHONG_DUYET_MucTieuJson");
            lstControl.Add("danh_gia_json");
            lstControl.Add("export_danh_gia_json");
            lstControl.Add("THI_danh_gia_json");
            lstControl.Add("THI_XemCanhBao_json");
            lstControl.Add("TaoCanhBao");
            lstControl.Add("LayDSNhanSuEmail");

            lstControl.Add("LUU_TaoDotPhanTichJson");
            lstControl.Add("LUU_PhanTich9HopJson");
            lstControl.Add("LUU_PhanTich9HopKetQuaJson");
            lstControl.Add("LUU_QuyUocJson");
            lstControl.Add("LUU_MoHinh9HopJson");

            lstControl.Add("LUU_AdminNhomQuyenJson");
            lstControl.Add("LUU_AdminPhanQuyenJson");
            lstControl.Add("LUU_AdminNguoiDungJson");

            lstControl.Add("LUU_CoCauToChucJson");
            lstControl.Add("LUU_CoCauChucDanhJson");
            lstControl.Add("LUU_CoCauNhanSuJson");
            lstControl.Add("LUU_CoCauNhomCapJson");
            
            lstControl.Add("XOA_CoCauToChucJson");
            lstControl.Add("XOA_CoCauChucDanhJson");
            lstControl.Add("XOA_CoCauNhanSuJson");
            lstControl.Add("XOA_CoCauNhomCapJson");

            lstControl.Add("XOA_TaoDotPhanTichJson");
            lstControl.Add("XOA_PhanTich9HopJson");
            lstControl.Add("XOA_QuyUocJson");
            lstControl.Add("XOA_MoHinh9HopJson");

            lstControl.Add("DUYET_CoCauToChucJson");
            lstControl.Add("DUYET_CoCauChucDanhJson");
            lstControl.Add("DUYET_CoCauNhanSuJson");
            lstControl.Add("DUYET_CoCauNhomCapJson");

            lstControl.Add("LUU_PhanHoi_duyet_muc_tieuJson");
            lstControl.Add("LUU_PhanHoi_duyet_nhap_ket_quaJson");
            lstControl.Add("LUU_MucTieuTrangThaiJson");
            lstControl.Add("pop-muc-tieu_con");
            lstControl.Add("pop_muc_tieu_conJson");
            
            lstControl.Add("XOA_MucTieuTaskJson");
            lstControl.Add("THEM_MucTieuTaskJson");
            lstControl.Add("SUA_MucTieuTaskJson");
            lstControl.Add("Lay_ds_muc_tieu_conJson");
            lstControl.Add("LUU_MucTieuConJson");
            lstControl.Add("KiemTraTrung_MucTieuConJson");
            lstControl.Add("SapXep_MucTieuConJson");
            lstControl.Add("LUU_Nhieu_MucTieuConJson");
            lstControl.Add("pop-doi-mat-khau");
            lstControl.Add("LUU_DoiMatKhauJson");
            
            lstControl.Add("DongBoCoCauJson");
            lstControl.Add("DongBoChucDanhJson");
            lstControl.Add("DongBoNhanSuJson");
            lstControl.Add("dong-bo-du-lieu");
            lstControl.Add("pop-dong-bo-co-cau");
            lstControl.Add("pop-dong-bo-chuc-danh");
            lstControl.Add("pop-dong-bo-nhan-su");

            lstControl.Add("pop-import-co-cau-to-chuc");
            lstControl.Add("import_co_cau_to_chuc_upload_json");
            lstControl.Add("pop-import-co-cau-chuc-danh");
            lstControl.Add("import_co_cau_chuc_danh_upload_json");
            lstControl.Add("pop-import-co-cau-nhan-su");
            lstControl.Add("import_co_cau_nhan_su_upload_json");

            lstControl.Add("export_co_cau_to_chuc_json");
            lstControl.Add("export_co_cau_chuc_danh_json");
            lstControl.Add("export_co_cau_nhan_su_json");


            lstControl.Add("DownloadFile"); 
            lstControl.Add("DownloadFileFull"); 
            lstControl.Add("GetJsonData");
            lstControl.Add("_canh_bao_loi");
            
            //lstControl.Add("aaa");
            //lstControl.Add("aaa");
            //lstControl.Add("aaa");
            //lstControl.Add("aaa");
            #endregion

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapHub<ProgressHub>("/ProgressHub");//SignalR

                //endpoints.MapControllerRoute(
                //    name: "muctieu", // Route name
                //    "muc-tieu/{id}", // URL with parameters
                //    pattern: "{controller=Home}/{action=Muc_tieu}/{id?}");
                for (int i = 0;i < lstControl.Count;i++)
                {
                    endpoints.MapControllerRoute(name: "List" + lstControl[i].Replace("-", "_"), pattern: lstControl[i] + "/{id?}", defaults: new { controller = "Home", action = lstControl[i].Replace("-", "_") });
                }

                //endpoints.MapControllerRoute(
                //    name: "blog",
                //    pattern: "blog/{*article}",
                //    defaults: new { controller = "Blog", action = "Article" });
                endpoints.MapControllerRoute(
                    name: "default",
                    pattern: "{controller}/{action}/{id?}",
                    defaults: new { controller = "Home", action = "Index" });

                //endpoints.MapControllerRoute(
                //    name: "default",
                //    pattern: "{controller=Home}/{action=Index}/{id?}");
            });
        }
    }
}
