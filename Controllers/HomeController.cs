using digiiTeamW.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using digiiTalentDTO;
using Zirpl.CalcEngine;
using System.Security.Claims;
using System.IO;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;

using System.Text.Json;
using System.Net.Http;
using System.Net.Http.Headers;

using Microsoft.AspNetCore.Hosting;//Upload file

using System.Threading;
using Microsoft.AspNetCore.SignalR;
using SignalR.Hubs;
using Coravel.Queuing.Interfaces;
using OfficeOpenXml.FormulaParsing.Excel.Functions.Engineering;
using System.Data;
using System.Data.SqlClient;
using System.Runtime.Serialization;
using System.Data.Linq;
using System.Text;
using System.Data.Linq.Mapping;

namespace digiiTeamW.Controllers
{
    public class HomeController : Controller
    {
        int _IDApp = 14;
        int _iDongBoAuto = 5;//Số phút tự động đồng bộ
        #region ActionID
        int ActionDashboardsXem = 537;//OK

        int ActionTaoDotPhanTichXem = 8;
        int ActionTaoDotPhanTichThem = 8;
        int ActionTaoDotPhanTichXoa = 8;

        int ActionPhanTich9HopXem = 8;
        int ActionPhanTich9HopThem = 8;
        int ActionPhanTich9HopXoa = 8;

        int ActionQuyUocXem = 8;
        int ActionQuyUocThem = 8;
        int ActionQuyUocXoa = 8;

        int ActionMoHinh9HopXem = 8;
        int ActionMoHinh9HopThem = 8;
        int ActionMoHinh9HopXoa = 8;

        int ActionNhomCapXem = 8;//OK
        int ActionNhomCapThem = 9;//OK
        int ActionNhomCapXoa = 10;//OK

        int ActionToChucXem = 11;//OK
        int ActionToChucThem = 12;//OK
        int ActionToChucXoa = 13;//OK

        int ActionChucDanhXem = 14;//OK
        int ActionChucDanhThem = 15;//OK
        int ActionChucDanhXoa = 16;//OK

        int ActionNhanSuXem = 17;//OK
        int ActionNhanSuThem = 18;//OK
        int ActionNhanSuXoa = 19;//OK

        int ActionNhomQuyenXem = 8;
        int ActionNhomQuyenThem = 8;
        int ActionNhomQuyenXoa = 8;

        int ActionPhanQuyenXem = 8;
        int ActionPhanQuyenThem = 8;
        int ActionPhanQuyenXoa = 8;

        int ActionNguoiDungXem = 8;
        int ActionNguoiDungThem = 8;
        int ActionNguoiDungXoa = 8;

        #endregion

        public IActionResult Index()
        {
            if (!IsAuthenticated())
                return RedirectToAction("login", "Home");
            else return Redirect("~/co-cau-nhom-cap");
            //return View();
        }
        public IActionResult thong_bao_loi()
        {
            return View();
        }
        public IActionResult _canh_bao_quyen()
        {
            return RedirectToAction("_canh_bao_quyen", "Home");
        }
        #region Base data
        private bool IsAuthenticated()
        {
            return HttpContext.User.Identity.IsAuthenticated;
        }
        private int _UserID(System.Security.Claims.ClaimsIdentity identity)
        {
            try
            {
                var val = identity.Claims.FirstOrDefault(c => c.Type == "UserID");
                if (val == null) return 0;
                else return Convert.ToInt32(val.Value);
            }
            catch (Exception ex)
            {
                return 0;
            }
        }
        private int _IDKhachHang(System.Security.Claims.ClaimsIdentity identity)
        {
            try
            {
                var val = identity.Claims.FirstOrDefault(c => c.Type == "IDKhachHang");
                if (val == null) return 0;
                else return Convert.ToInt32(val.Value);
            }
            catch
            {
                return 0;
            }
        }
        private string _UserName(System.Security.Claims.ClaimsIdentity identity)
        {
            try
            {
                var val = identity.Claims.FirstOrDefault(c => c.Type == "UserName");
                if (val == null) return "";
                else return val.Value.ToString();
            }
            catch (Exception ex)
            {
                return "NA";
            }
        }
        private string _UserCode(System.Security.Claims.ClaimsIdentity identity)
        {
            try
            {
                var val = identity.Claims.FirstOrDefault(c => c.Type == "UserCode");
                if (val == null) return "";
                else return val.Value.ToString();
            }
            catch (Exception ex)
            {
                return "NA";
            }
        }
        private string _UserEmail(System.Security.Claims.ClaimsIdentity identity)
        {
            try
            {
                var val = identity.Claims.FirstOrDefault(c => c.Type == "UserEmail");
                if (val == null) return "";
                else return val.Value.ToString();
            }
            catch (Exception ex)
            {
                return "NA";
            }
        }
        private Int64? _IDCoCau(System.Security.Claims.ClaimsIdentity identity)
        {
            try
            {
                var val = identity.Claims.FirstOrDefault(c => c.Type == "IDCoCau");
                if (val == null) return 0;
                else return Convert.ToInt64(val);
            }
            catch (Exception ex)
            {
                return 0;
            }
        }
        private Int64? _IDChucDanh(System.Security.Claims.ClaimsIdentity identity)
        {
            try
            {
                var val = identity.Claims.FirstOrDefault(c => c.Type == "IDChucDanh");
                if (val == null) return 0;
                else return Convert.ToInt64(val);
            }
            catch (Exception ex)
            {
                return 0;
            }
        }
        private string _ListQuyen(System.Security.Claims.ClaimsIdentity identity)
        {
            try
            {
                var val = identity.Claims.FirstOrDefault(c => c.Type == "ListQuyen");
                if (val == null) return "";
                else return val.Value.ToString();
            }
            catch (Exception ex)
            {
                return "NA";
            }
        }
        private string _ImagePath(System.Security.Claims.ClaimsIdentity identity)
        {
            try
            {
                var val = identity.Claims.FirstOrDefault(c => c.Type == "ImagePath");
                if (val == null) return "";
                else return val.Value.ToString();
            }
            catch (Exception ex)
            {
                return "NA";
            }
        }
        private ObjectAspUser BaseUser()
        {
            ObjectAspUser obj = new ObjectAspUser();
            var identity = (System.Security.Claims.ClaimsIdentity)HttpContext.User.Identity;

            obj.UserID = _UserID(identity);
            obj.IDKhachHang = _IDKhachHang(identity);
            obj.UserName = _UserName(identity);
            obj.UserCode = _UserCode(identity);
            obj.UserEmail = _UserEmail(identity);
            obj.IDCoCau = _IDCoCau(identity);
            obj.IDChucDanh = _IDChucDanh(identity);
            obj.ImagePath = _ImagePath(identity);
            obj.ListQuyen = _ListQuyen(identity);
            return obj;
        }
        private DefaultUser getDefaultUser(ObjectAspUser user)
        {
            DefaultUser obj = new DefaultUser();
            obj.UserID = user.UserID;
            obj.UserCode = user.UserCode;
            obj.UserName = user.UserName;
            obj.IDKhachHang = user.IDKhachHang;
            obj.ImagePath = user.ImagePath;
            return obj;
        }
        public IConfigurationRoot GetConfigurationLabel()
        {
            var builder = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory()).AddJsonFile("label.json", optional: true, reloadOnChange: true);
            return builder.Build();
        }
        public IConfigurationRoot GetConfiguration()
        {
            var builder = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory()).AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
            return builder.Build();
        }
        public string GetTenChucNang(int IDChucNang)
        {
            try
            {
                var config = GetConfigurationLabel();
                return config["ChucNang:ChucNang" + IDChucNang.ToString()].ToString();
            }
            catch (Exception ex)
            {
                return "NA";
            }
        }
        public string GetSettingURL()
        {
            try { var config = GetConfiguration(); return config["CauHinh:settingURL"].ToString().Trim('/'); } catch { return ""; }
        }
        public string GetLocalURL()
        {
            try { var config = GetConfiguration(); return config["CauHinh:localURL"].ToString().Trim('/'); } catch { return ""; }
        }
        public string GetLabel_MaTichHop()
        {
            try { var config = GetConfigurationLabel(); return config["CauHinh:MaTichHop"].ToString(); } catch { return ""; }
        }
        public int GetLabel_SuDungTepDinhkem()
        {
            try { var config = GetConfigurationLabel(); return Convert.ToInt32(config["TichHop:SuDungTepDinhkem"]); } catch { return 0; }
        }
        public int GetLabel_KichThuocTepDinhkem()
        {
            try { var config = GetConfigurationLabel(); return Convert.ToInt32(config["TichHop:KichThuocTepDinhkem"]); } catch { return 1048576; }//1 MB
        }
        public int GetLabel_SuDung()
        {
            try { var config = GetConfigurationLabel(); return Convert.ToInt32(config["TichHop:SuDungTichHop"]); } catch { return 0; }
        }
        public string GetLabel_TichHop_apiKey()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:apiKey"].ToString(); } catch { return ""; }
        }
        public int GetLabel_NgayDauThang()
        {
            try { var config = GetConfigurationLabel(); return Convert.ToInt32(config["TichHop:NgayDauThang"]); } catch { return 1; }
        }
        public string GetLabel_DoanhSo()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:DoanhSo"].ToString().Trim('/'); } catch { return ""; }
        }
        public string GetLabel_DoanhThu()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:DoanhThu"].ToString().Trim('/'); } catch { return ""; }
        }
        public string GetLabel_KhachHang()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:KhachHang"].ToString().Trim('/'); } catch { return ""; }
        }
        public string GetLabel_SanPham()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:SanPham"].ToString().Trim('/'); } catch { return ""; }
        }

        public string GetLoginURL()
        {
            try
            {
                var config = GetConfiguration();
                string localURL = config["CauHinh:localURL"].ToString();
                if (localURL.ToLower() == "login") return localURL;
                string api = config["CauHinh:loginURL"].ToString();
                if (api.ToLower().StartsWith("http")) return api;
                else return localURL.Trim('/') + "/" + api;
            }
            catch { return ""; }
        }
        public string GetUrlAnhNhanSu()
        {
            try
            {
                var config = GetConfiguration();
                string localURL = config["CauHinh:localURL"].ToString();
                string api = config["CauHinh:urlAnhNhanSu"].ToString();
                if (api.ToLower().StartsWith("http")) return api;
                else return localURL.Trim('/') + "/" + api;
            }
            catch { return ""; }
        }
        public string GetApiToken()
        {
            try
            {
                var config = GetConfiguration();
                string localURL = config["CauHinh:localURL"].ToString();
                string api = config["CauHinh:apiToken"].ToString();
                if (api.ToLower().StartsWith("http")) return api;
                else return localURL.Trim('/') + "/" + api;
            }
            catch { return ""; }
            //try { var config = GetConfiguration(); return config["CauHinh:apiToken"].ToString(); } catch { return ""; }
        }
        public string GetPhanQuyenAcc()
        {
            try { var config = GetConfiguration(); return config["CauHinh:PhanQuyenAcc"].ToString(); } catch { return ""; }
        }
        public string GetPhanQuyenPass()
        {
            try { var config = GetConfiguration(); return Helper.StringDecrypt(config["CauHinh:PhanQuyenPass"].ToString()); } catch { return ""; }
        }
        public string GetApiDSPhanQuyen()
        {
            try
            {
                var config = GetConfiguration();
                string localURL = config["CauHinh:localURL"].ToString();
                string api = config["CauHinh:apiDSPhanQuyen"].ToString();
                if (api.ToLower().StartsWith("http")) return api;
                else return localURL.Trim('/') + "/" + api;
            }
            catch { return ""; }
            //try { var config = GetConfiguration(); return config["CauHinh:apiDSPhanQuyen"].ToString(); } catch { return ""; }
        }
        public string GetApiDSKhachHang()
        {
            try
            {
                var config = GetConfiguration();
                string localURL = config["CauHinh:localURL"].ToString();
                string api = config["CauHinh:apiDSKhachHang"].ToString();
                if (api.ToLower().StartsWith("http")) return api;
                else return localURL.Trim('/') + "/" + api;
            }
            catch { return ""; }
            //try { var config = GetConfiguration(); return config["CauHinh:apiDSKhachHang"].ToString(); } catch { return ""; }
        }
        public string GetApiDSCoCau()
        {
            try
            {
                var config = GetConfiguration();
                string localURL = config["CauHinh:localURL"].ToString();
                string api = config["CauHinh:apiDSCoCau"].ToString();
                if (api.ToLower().StartsWith("http")) return api;
                else return localURL.Trim('/') + "/" + api;
            }
            catch { return ""; }
            //try { var config = GetConfiguration(); return config["CauHinh:apiDSCoCau"].ToString(); } catch { return ""; }
        }
        public string GetApiDSChucDanh()
        {
            try
            {
                var config = GetConfiguration();
                string localURL = config["CauHinh:localURL"].ToString();
                string api = config["CauHinh:apiDSChucDanh"].ToString();
                if (api.ToLower().StartsWith("http")) return api;
                else return localURL.Trim('/') + "/" + api;
            }
            catch { return ""; }
            //try { var config = GetConfiguration(); return config["CauHinh:apiDSChucDanh"].ToString(); } catch { return ""; }
        }
        public string GetApiDSNhanSu()
        {
            try
            {
                var config = GetConfiguration();
                string localURL = config["CauHinh:localURL"].ToString();
                string api = config["CauHinh:apiDSNhanSu"].ToString();
                if (api.ToLower().StartsWith("http")) return api;
                else return localURL.Trim('/') + "/" + api;
            }
            catch { return ""; }
            //try { var config = GetConfiguration(); return config["CauHinh:apiDSNhanSu"].ToString(); } catch { return ""; }
        }
        public string GetApiDSNamTaiChinh()
        {
            try
            {
                var config = GetConfiguration();
                string localURL = config["CauHinh:localURL"].ToString();
                string api = config["CauHinh:apiDSNamTaiChinh"].ToString();
                if (api.ToLower().StartsWith("http")) return api;
                else return localURL.Trim('/') + "/" + api;
            }
            catch { return ""; }
            //try { var config = GetConfiguration(); return config["CauHinh:apiDSNamTaiChinh"].ToString(); } catch { return ""; }
        }
        #endregion

        #region Label
        private void initLabel()
        {
            var config = GetConfigurationLabel();
            try { ViewData["SoThucTe"] = config["CauHinh:SoThucTe"].ToString(); } catch { ViewData["SoThucTe"] = "Số thực tế"; }
            try { ViewData["DanhGia"] = config["CauHinh:DanhGia"].ToString(); } catch { ViewData["DanhGia"] = "Đánh giá"; }
            try { ViewData["TrongSo"] = config["CauHinh:TrongSo"].ToString(); } catch { ViewData["TrongSo"] = "Trọng số"; }
        }
        #endregion

        #region Login
        [AllowAnonymous]
        public IActionResult login(string username, string password)
        {
            string url = GetLoginURL();
            if (url.ToLower() != "login") return new RedirectResult(url);
            int QuyenXem = 1;
            string err = "";
            try
            {
                HttpContext.SignOutAsync();
            }
            catch (Exception)
            {
                HttpContext.SignOutAsync();
            }
            if (string.IsNullOrEmpty(username) && string.IsNullOrEmpty(password))
            {
                //err = Helper.ErrorNull("Tài khoản");
                //TempData["error"] = err;
                return ValidateView(QuyenXem, "login");
            }
            try
            {
                DTOBase b = new DTOBase();
                var obj = b.sp_Login(username, ref err);
                if (obj == null)
                {
                    try { HttpContext.SignOutAsync(); } catch { }
                    TempData["error"] = "Tài khoản không tồn tại";
                    return ValidateView(QuyenXem, "login");
                }
                if (obj != null)
                {
                    //Get User Right
                    string ListQuyen = "";
                    string token = "";

                    if (obj.IDNhanSu > 0)
                    {
                        //string PhanQuyenAcc = username;
                        //string PhanQuyenPass = password;
                        //var reqdata = new { reqdata = new { UserName = PhanQuyenAcc, Password = PhanQuyenPass } };
                        //ApiObjectLogin objToken = new ApiObjectLogin();
                        //try
                        //{
                        //    objToken = JsonSerializer.Deserialize<ApiObjectLogin>(Helper.apiPost(GetApiToken(), JsonSerializer.Serialize(reqdata), token));
                        //}
                        //catch (Exception ex)
                        //{
                        //    err = "Error -1: [ApiToken] " + ex.Message;
                        //    goto Finished;
                        //}

                        //if (objToken == null)
                        //{
                        //    err = "Error -2: ApiToken is null";
                        //    goto Finished;
                        //}
                        //if (string.IsNullOrEmpty(objToken.access_token))
                        //{
                        //    err = "Error -3: access_token is null";
                        //    goto Finished;
                        //}
                        //var reqlist = new { Username = username, IDApp = _IDApp };
                        //List<ApiObjectPhanQuyen> list;
                        //try
                        //{
                        //    list = JsonSerializer.Deserialize<List<ApiObjectPhanQuyen>>(Helper.apiPost(GetApiDSPhanQuyen(), JsonSerializer.Serialize(reqlist), objToken.access_token));
                        //    //Lưu danh sách quyền User
                        //    int iMax = list.Count();

                        //    for (int i = 0; i < iMax; i++)
                        //    {
                        //        if (list[i].DataType > -1)
                        //        {
                        //            ListQuyen += list[i].ActionID.ToString() + "=" + list[i].DataType.ToString() + "|";
                        //        }
                        //    }
                        //}
                        //catch (Exception ex)
                        //{
                        //    err = "Error -4: [User Rights] " + ex.Message;
                        //    goto Finished;
                        //}
                        ListQuyen = ListQuyen.Trim('|');
                    }

                    var claims = new List<Claim>
                        {
                            new Claim("UserID", Helper.NullToEmpty(obj.IDNhanSu)),
                            new Claim("UserCode", Helper.NullToEmpty(obj.MaNhanSu)),
                            new Claim("UserName", Helper.NullToEmpty(obj.HoVaTen)),
                            new Claim("ImagePath", Helper.NullToEmpty(obj.AnhNhanSu)),
                            new Claim("IDCoCau", Helper.NullToEmpty(obj.IDCoCau)),
                            new Claim("IDChucDanh", Helper.NullToEmpty(obj.IDChucDanh)),
                            new Claim("UserEmail", username),
                            new Claim("ListQuyen", obj.dsQuyen),
                            new Claim("IDKhachHang", Helper.NullToEmpty(obj.IDKhachHang)),
                            new Claim(ClaimTypes.Role, "User"),
                        };

                    var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                    var authProperties = new AuthenticationProperties
                    {
                        ExpiresUtc = DateTimeOffset.UtcNow.AddDays(30),
                        IsPersistent = true,
                        AllowRefresh = true
                    };
                    HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(claimsIdentity), authProperties);

                    if (obj.IDNhanSu == 0)
                    {
                        //return RedirectToAction("co-cau-to-chuc", "Home");
                        return Redirect("~/co-cau-to-chuc");
                    }
                    else return Redirect("~/co-cau-nhom-cap");

                }
            }
            catch (Exception ex)
            {
                err = ex.Message;
                TempData["error"] = err;
                return ValidateView(QuyenXem, "login");
            }
        Finished:
            if (!string.IsNullOrEmpty(err))
            {
                ViewData["PageTitle"] = "Lỗi đăng nhập";
                TempData["error"] = err;
                return RedirectToAction("login", "Home");
                //return View("_canh_bao_loi", "Home");
            }
            return Redirect("~/co-cau-nhom-cap");
        }
        [AllowAnonymous]
        public IActionResult logout()
        {
            HttpContext.SignOutAsync();
            return RedirectToAction("login", "Home");
        }
        [AllowAnonymous]
        public IActionResult hrs(string ID)
        {
            string err = "";
            try
            {
                HttpContext.SignOutAsync();
            }
            catch (Exception)
            {
                HttpContext.SignOutAsync();
            }
            if (string.IsNullOrEmpty(ID))
            {
                err = Helper.ErrorNull("Tài khoản");
                goto Finished;
                //return RedirectToAction("login", "Home");
            }
            string username = Helper.StringDecrypt(ID);
            try
            {
                DTOBase b = new DTOBase();
                var obj = b.sp_Login(username, ref err);
                if (obj == null)
                {
                    obj = new NhanSu_Login();
                    obj.IDNhanSu = 0;
                    obj.MaNhanSu = "Chưa đồng bộ";
                    obj.HoVaTen = username;
                    obj.AnhNhanSu = "";
                    obj.IDKhachHang = 0;
                }
                if (obj != null)
                {
                    //Get User Right
                    string ListQuyen = "";
                    string token = "";

                    if (obj.IDNhanSu > 0)
                    {
                        string PhanQuyenAcc = GetPhanQuyenAcc();
                        string PhanQuyenPass = GetPhanQuyenPass();
                        var reqdata = new { reqdata = new { UserName = PhanQuyenAcc, Password = PhanQuyenPass } };
                        ApiObjectLogin objToken = new ApiObjectLogin();
                        try
                        {
                            objToken = JsonSerializer.Deserialize<ApiObjectLogin>(Helper.apiPost(GetApiToken(), JsonSerializer.Serialize(reqdata), token));
                        }
                        catch (Exception ex)
                        {
                            err = "Error -1: [ApiToken] " + ex.Message;
                            goto Finished;
                        }

                        if (objToken == null)
                        {
                            err = "Error -2: ApiToken is null";
                            goto Finished;
                        }
                        if (string.IsNullOrEmpty(objToken.access_token))
                        {
                            err = "Error -3: access_token is null";
                            goto Finished;
                        }
                        var reqlist = new { Username = username, IDApp = _IDApp };
                        List<ApiObjectPhanQuyen> list;
                        try
                        {
                            list = JsonSerializer.Deserialize<List<ApiObjectPhanQuyen>>(Helper.apiPost(GetApiDSPhanQuyen(), JsonSerializer.Serialize(reqlist), objToken.access_token));
                            //Lưu danh sách quyền User
                            b.LUU_PhanQuyen(list, obj.IDNhanSu);
                            int iMax = list.Count();

                            for (int i = 0; i < iMax; i++)
                            {
                                if (list[i].DataType > -1)
                                {
                                    ListQuyen += list[i].ActionID.ToString() + "=" + list[i].DataType.ToString() + "|";
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            err = "Error -4: [User Rights] " + ex.Message;
                            goto Finished;
                        }
                        ListQuyen = ListQuyen.Trim('|');
                    }

                    var claims = new List<Claim>
                    {
                        new Claim("UserID", Helper.NullToEmpty(obj.IDNhanSu)),
                        new Claim("UserCode", Helper.NullToEmpty(obj.MaNhanSu)),
                        new Claim("UserName", Helper.NullToEmpty(obj.HoVaTen)),
                        new Claim("ImagePath", Helper.NullToEmpty(obj.AnhNhanSu)),
                        new Claim("IDCoCau", Helper.NullToEmpty(obj.IDCoCau)),
                        new Claim("IDChucDanh", Helper.NullToEmpty(obj.IDChucDanh)),
                        new Claim("UserEmail", username),
                        new Claim("ListQuyen", obj.dsQuyen),
                        new Claim("IDKhachHang", Helper.NullToEmpty(obj.IDKhachHang)),
                        new Claim(ClaimTypes.Role, "User"),
                    };

                    var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                    var authProperties = new AuthenticationProperties
                    {
                        ExpiresUtc = DateTimeOffset.UtcNow.AddDays(30),
                        IsPersistent = true,
                        AllowRefresh = true
                    };
                    HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(claimsIdentity), authProperties);

                    if (obj.IDNhanSu == 0)
                    {
                        //return RedirectToAction("co-cau-to-chuc", "Home");
                        return Redirect("~/co-cau-to-chuc");
                    }
                    else return Redirect("~/co-cau-nhom-cap");

                }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
        Finished:
            if (!string.IsNullOrEmpty(err))
            {
                ViewData["PageTitle"] = "Lỗi đăng nhập";
                TempData["error"] = err;
                return View("_canh_bao_loi", "Home");
            }
            return RedirectToAction("dashboards", "Home");
        }
        #endregion

        [AllowAnonymous]
        public string hrs_encrypt(string id)
        {
            if (string.IsNullOrEmpty(id)) return "";
            else return Helper.StringEncrypt(id);
        }
        ViewResult ValidateView(int QuyenXem, string ViewName)
        {
            ViewData["SettingURL"] = GetSettingURL();
            if (QuyenXem <= 0) return View("_canh_bao_quyen");
            return View(ViewName);
        }
        [Authorize]
        public IActionResult bao_cao()
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            if (user.UserID == 0)
            {
                ViewData["urlRefresh"] = hrs_encrypt(user.UserName);
            }
            int ActionXem = ActionDashboardsXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);

            int IDChucNang = 1;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["dashboards"] = "class=active";

            long? idHTMT = null;
            //ViewData["ddlHeThongMucTieu"] = he_thong_muc_tieu_JsonDDL(ActionXem, ref idHTMT);

            //byte? IDLoaiTanSuat = null;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            ViewData["ddlChuThe"] = chu_the_chi_tieu_JsonDDL(idNhomCap, ActionXem, -3);

            return ValidateView(QuyenXem, "bao_cao");
        }
        [Authorize]
        public JsonResult bao_cao_json(string idHTMT, string idNhomCap, string idLoaiTanSuat, string idHTTS, byte? chuThe, string idCoCau, string idCoCauPhuTrach, string idNguoiPhuTrach, string idLoaiMucTieu, int? topBongBong, int? topNhom, int? topMucTieu, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = 1;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 1;
            string err = "";
            ObjectPager pager = new ObjectPager();
            ChartGauge gauge = new ChartGauge();
            var result = 1;
            return Json(result);
        }
        [AllowAnonymous]
        [HttpGet]
        //[DeleteFileAttribute] //Action Filter, it will auto delete the file after download, 
        //I will explain it later
        public ActionResult DownloadFile(string file)
        {
            var user = BaseUser();
            string fullPath = "tmp/" + user.UserID + "/" + file;
            if (!System.IO.File.Exists(fullPath)) fullPath = "";

            byte[] fileBytes = Helper.GetFile(fullPath);
            return File(fileBytes, System.Net.Mime.MediaTypeNames.Application.Octet, file);
        }

        [HttpPost]
        public ActionResult muc_tieu_upload_json(IFormFile file)
        {
            var user = BaseUser();
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = 1;
            string err = "";
            string path = "";
            try
            {
                if (file != null)
                {
                    var sTime = user.UserID + "_" + DateTime.Now.ToString("yyyyMMddHHmmss");
                    path = "uploads/" + sTime + "_" + file.FileName;
                    using (var stream = new FileStream(path, FileMode.Create))
                    {
                        file.CopyTo(stream);
                    }
                    //Read file
                    //path = Helper.Import_ChiTieu(path, pager, user, ref err);
                    // do something
                }
            }
            catch (Exception ex)
            {
                err = ex.ToString();
            }

            var result = new { path = path, err = err };
            return Json(result);
        }
        public async Task<JsonResult> muc_tieu_upload_json1(IFormFile files)
        {
            var resultList = new List<UploadFilesResult>();
            string path = "uploads/" + files.FileName;

            using (var stream = new FileStream(path, FileMode.Create))
            {
                await files.CopyToAsync(stream);
            }

            UploadFilesResult uploadFiles = new UploadFilesResult();
            uploadFiles.name = files.FileName;
            uploadFiles.size = files.Length;
            uploadFiles.type = "image/jpeg";
            uploadFiles.url = "/uploads/" + files.FileName;
            uploadFiles.deleteUrl = "/Home/Delete?file=" + files.FileName;
            uploadFiles.thumbnailUrl = "/uploads/" + files.FileName;
            uploadFiles.deleteType = "GET";

            resultList.Add(uploadFiles);
            return Json(new { files = resultList });
        }
        [Authorize]
        public IActionResult pop_danh_gia_file_dinh_kem(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int QuyenImport = Helper.GetQuyen(user.ListQuyen, 1);


            ViewData["QuyenImport"] = QuyenImport;
            ViewData["IDMucTieu"] = id;
            ViewData["objList"] = getFileDinhKem(user, id);
            ViewData["KichThuocTepDinhkem"] = GetLabel_KichThuocTepDinhkem();
            return ValidateView(QuyenImport, "pop-danh-gia-file-dinh-kem");
        }
        List<ObjectFile> getFileDinhKem(ObjectAspUser user, string id)
        {
            List<ObjectFile> objList = new List<ObjectFile>();
            try
            {
                ObjectFile obj = new ObjectFile();
                string pathRoot = "Files/" + user.IDKhachHang.ToString() + "/" + id.ToString();
                if (!Directory.Exists(pathRoot)) Directory.CreateDirectory(pathRoot);
                DirectoryInfo d = new DirectoryInfo(pathRoot); //Assuming Test is your Folder
                FileInfo[] Files = d.GetFiles().OrderByDescending(p => p.CreationTime).ToArray(); ; //Getting Text files

                long iGB = 1024 * 1024 * 1024;
                long iMB = 1024 * 1024;
                long iKB = 1024;

                foreach (FileInfo file in Files)
                {
                    obj = new ObjectFile();
                    obj.FileName = file.Name;
                    obj.NgayTao = file.CreationTime.ToString("yyyy-MM-dd");
                    obj.FilePath = System.Web.HttpUtility.UrlEncode(pathRoot + "/") + System.Web.HttpUtility.UrlPathEncode(file.Name);
                    long iSize = file.Length;
                    if (iSize > iGB)
                        obj.FileSize = (iSize / iGB).ToString() + " GB";
                    else if (iSize > iMB)
                        obj.FileSize = (iSize / iMB).ToString() + " MB";
                    else if (iSize > iKB)
                        obj.FileSize = (iSize / iKB).ToString() + " KB";
                    else obj.FileSize = iSize.ToString() + " B";
                    objList.Add(obj);
                }
            }
            catch (Exception ex)
            {
                string err = ex.Message;
            }

            return objList;
        }
        public FileResult DownloadFileFull(string id)
        {
            //Build the File Path.
            //string path = Server.MapPath("~/Files/") + fileName;
            string path = System.Web.HttpUtility.UrlDecode(id);

            //Read the File data into Byte Array.
            byte[] bytes = System.IO.File.ReadAllBytes(path);
            string name = Path.GetFileName(path);
            //Send the File to Download.
            return File(bytes, "application/octet-stream", name);

            //if (!System.IO.File.Exists(fullPath)) fullPath = "";

            //byte[] fileBytes = Helper.GetFile(fullPath);
            //return File(fileBytes, System.Net.Mime.MediaTypeNames.Application.Octet, file);
        }
        int countFileDinhKem(ObjectAspUser user, string id)
        {
            int iCount = 0;
            try
            {
                string pathRoot = "Files/" + user.IDKhachHang.ToString() + "/" + id.ToString();
                if (!Directory.Exists(pathRoot)) Directory.CreateDirectory(pathRoot);
                DirectoryInfo d = new DirectoryInfo(pathRoot); //Assuming Test is your Folder
                FileInfo[] Files = d.GetFiles().OrderByDescending(p => p.CreationTime).ToArray(); ; //Getting Text files
                iCount = Files.Length;

            }
            catch (Exception ex)
            {
                string err = ex.Message;
            }
            return iCount;
        }
        //=================================================
        [Authorize]
        public IActionResult mo_hinh_9_hop()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionToChucThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionToChucXoa);
            //ViewData["QuyenDongBo"] = Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            int IDChucNang = 5;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["mo-hinh-9-hop"] = "class=active";
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            return ValidateView(QuyenXem, "mo-hinh-9-hop");
        }



        [Authorize]
        public JsonResult mo_hinh_9_hop_json(string idNhomCap, string idCocau, string suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 5;
            string err = "";
            List<SYS_CoCauBase> list = new List<SYS_CoCauBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                byte? idNhomCapNew = null;
                System.Nullable<long> iDChaNew = null;
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(idNhomCap)) idNhomCapNew = Helper.ToByte(idNhomCap);
                if (!string.IsNullOrEmpty(idCocau)) iDChaNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSCoCau(idNhomCapNew, iDChaNew, suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult quy_uoc()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionToChucThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionToChucXoa);
            //ViewData["QuyenDongBo"] = Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            int IDChucNang = 4;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["quy-uoc"] = "class=active";
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            return ValidateView(QuyenXem, "quy-uoc");
        }
        [Authorize]
        public JsonResult quy_uoc_json(string idNhomCap, string idCocau, string suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 4;
            string err = "";
            List<SYS_CoCauBase> list = new List<SYS_CoCauBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                byte? idNhomCapNew = null;
                System.Nullable<long> iDChaNew = null;
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(idNhomCap)) idNhomCapNew = Helper.ToByte(idNhomCap);
                if (!string.IsNullOrEmpty(idCocau)) iDChaNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSCoCau(idNhomCapNew, iDChaNew, suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult phan_tich_9_hop()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionToChucThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionToChucXoa);
            //ViewData["QuyenDongBo"] = Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            int IDChucNang = 3;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["phan-tich-9-hop"] = "class=active";
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            return ValidateView(QuyenXem, "phan-tich-9-hop");
        }
        [Authorize]
        public JsonResult phan_tich_9_hop_json(string idNhomCap, string idCocau, string suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 3;
            string err = "";
            List<SYS_CoCauBase> list = new List<SYS_CoCauBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                byte? idNhomCapNew = null;
                System.Nullable<long> iDChaNew = null;
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(idNhomCap)) idNhomCapNew = Helper.ToByte(idNhomCap);
                if (!string.IsNullOrEmpty(idCocau)) iDChaNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSCoCau(idNhomCapNew, iDChaNew, suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult tao_dot_phan_tich()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionToChucThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionToChucXoa);
            //ViewData["QuyenDongBo"] = Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            int IDChucNang = 2;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["tao-dot-phan-tich"] = "class=active";
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            return ValidateView(QuyenXem, "tao-dot-phan-tich");
        }
        [Authorize]
        public JsonResult tao_dot_phan_tich_json(string idNhomCap, string idCocau, string suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 2;
            string err = "";
            List<SYS_CoCauBase> list = new List<SYS_CoCauBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                byte? idNhomCapNew = null;
                System.Nullable<long> iDChaNew = null;
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(idNhomCap)) idNhomCapNew = Helper.ToByte(idNhomCap);
                if (!string.IsNullOrEmpty(idCocau)) iDChaNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSCoCau(idNhomCapNew, iDChaNew, suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }

        [Authorize]
        public IActionResult admin_nhom_quyen()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionToChucThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionToChucXoa);
            //ViewData["QuyenDongBo"] = Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            int IDChucNang = 50;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["admin-nhom-quyen"] = "class=active";
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            DTOBase dto = new DTOBase();
            DataTable dataTable = new DataTable();
            string connString = dto._connection;
            string query = "select * from [dbo].[Setting_Form]";

            SqlConnection conn = new SqlConnection(connString);
            SqlCommand cmd = new SqlCommand(query, conn);
            conn.Open();

            // create data adapter
            SqlDataAdapter da = new SqlDataAdapter(cmd);
            // this will query your database and return the result to your datatable
            da.Fill(dataTable);
            conn.Close();
            da.Dispose();
            ViewData["ddlNhomQuyen"] = da;
            return ValidateView(QuyenXem, "admin-nhom-quyen");
        }
        [Authorize]
        public JsonResult admin_nhom_quyen_json(string idNhomCap, string idCocau, string suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 50;
            string err = "";
            List<SYS_CoCauBase> list = new List<SYS_CoCauBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                byte? idNhomCapNew = null;
                System.Nullable<long> iDChaNew = null;
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(idNhomCap)) idNhomCapNew = Helper.ToByte(idNhomCap);
                if (!string.IsNullOrEmpty(idCocau)) iDChaNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSCoCau(idNhomCapNew, iDChaNew, suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult admin_phan_quyen()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionToChucThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionToChucXoa);
            //ViewData["QuyenDongBo"] = Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            int IDChucNang = 51;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["admin-phan-quyen"] = "class=active";
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);

            //Lấy cột của bảng trực tiếp từ dbo.Setting_Form

            DTOBase dto = new DTOBase();
            string connString = dto._connection;

            DataTable settingFormGroupTable = new DataTable();
            DataTable settingFormTable = new DataTable();
            DataTable settingActionTable = new DataTable();

            string fetchFormGroupTableQuery = "SELECT * FROM [Setting_FormGroup]";
            string fetchFormTableQuery = "SELECT IDForm,IDGroup,TenForm FROM [Setting_Form]";
            string fetchActionTableQuery = "SELECT IDAction,IDForm,TenAction FROM [Setting_Action]";

            SqlConnection conn = new SqlConnection(connString);
            SqlCommand cmd = new SqlCommand(fetchFormGroupTableQuery, conn);
            conn.Open();

            SqlDataAdapter da = new SqlDataAdapter(cmd);
            da.Fill(settingFormGroupTable);

            cmd = new SqlCommand(fetchFormTableQuery, conn);
            da = new SqlDataAdapter(cmd);
            da.Fill(settingFormTable);

            cmd = new SqlCommand(fetchActionTableQuery, conn);
            da = new SqlDataAdapter(cmd);
            da.Fill(settingActionTable);

            conn.Close();
            da.Dispose();

            String tmp = "";
            tmp = tmp + '[';

            foreach (DataRow groupRow in settingFormGroupTable.Rows)
            {
                tmp = tmp + "{";
                tmp = tmp + "\"name\":\"" + groupRow["TenGoup"] + "\",";
                tmp = tmp + "\"layer\":" + "1" + ",";



                //layer 2

                tmp = tmp + "\"childs\":";
                tmp = tmp + '[';

                foreach (DataRow formRow in settingFormTable.Rows)
                    if (formRow["IDGroup"].Equals(groupRow["IDGroup"]))
                    {
                        tmp = tmp + "{";
                        tmp = tmp + "\"name\":\"" + formRow["TenForm"] + "\",";
                        tmp = tmp + "\"layer\":" + "2" + ",";


                        //layer 3

                        tmp = tmp + "\"childs\":";
                        tmp = tmp + '[';

                        foreach (DataRow actionRow in settingActionTable.Rows)
                            if (actionRow["IDForm"].Equals(formRow["IDForm"]))
                            {
                                tmp = tmp + "{";
                                tmp = tmp + "\"name\":\"" + actionRow["TenAction"] + "\",";
                                tmp = tmp + "\"layer\":" + "3" + ",";
                                tmp = tmp + "},";
                            }
                        tmp = tmp + ']';


                        //end of layer 3

                        tmp = tmp + "},";

                    }
                tmp = tmp + "]";

                tmp = tmp + "},";
            }

            tmp = tmp + "]";

            ViewData["PhanQuyenJson"] = tmp;


            string query = "SELECT STT,TenForm FROM [Setting_Form]";

            DataTable dataTable = new DataTable();
            cmd = new SqlCommand(query, conn);
            da = new SqlDataAdapter(cmd);
            da.Fill(dataTable);
            conn.Close();
            da.Dispose();

            List<ObjectDDL> ddl = new List<ObjectDDL>();
            ObjectDDL obj;


            for (int i = 0; i < dataTable.Rows.Count; i++)
            {
                obj = new ObjectDDL();
                obj.id = (long?)long.Parse(dataTable.Rows[i]["STT"].ToString());
                obj.text = dataTable.Rows[i]["TenForm"].ToString();
                ddl.Add(obj);
            }

            ViewData["ddlNhomQuyen"] = Json(ddl);


            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            return ValidateView(QuyenXem, "admin-phan-quyen");
        }
        [Authorize]
        public JsonResult admin_phan_quyen_json(string idNhomCap, string idCocau, string suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 51;
            string err = "";
            List<SYS_CoCauBase> list = new List<SYS_CoCauBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                byte? idNhomCapNew = null;
                System.Nullable<long> iDChaNew = null;
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(idNhomCap)) idNhomCapNew = Helper.ToByte(idNhomCap);
                if (!string.IsNullOrEmpty(idCocau)) iDChaNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSCoCau(idNhomCapNew, iDChaNew, suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult admin_nguoi_dung()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionToChucThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionToChucXoa);
            //ViewData["QuyenDongBo"] = Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            int IDChucNang = 52;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["admin-nguoi-dung"] = "class=active";
            ViewData["ddlChucDanh"] = chuc_danh_search_JsonDDL(null, null, ActionXem);
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(null, ActionXem);


            //Lấy giá trị của bảng setting form trực tiếp từ Database

            DTOBase dto = new DTOBase();
            DataTable dataTable = new DataTable();

            string connString = dto._connection;
            string query = "SELECT STT,TenForm FROM [Setting_Form]";

            SqlConnection conn = new SqlConnection(connString);
            SqlCommand cmd = new SqlCommand(query, conn);
            conn.Open();

            SqlDataAdapter da = new SqlDataAdapter(cmd);
            da.Fill(dataTable);
            conn.Close();
            da.Dispose();

            List<ObjectDDL> ddl = new List<ObjectDDL>();
            ObjectDDL obj;


            for (int i = 0; i < dataTable.Rows.Count; i++)
            {
                obj = new ObjectDDL();
                obj.id = (long?)long.Parse(dataTable.Rows[i]["STT"].ToString());
                obj.text = dataTable.Rows[i]["TenForm"].ToString();
                ddl.Add(obj);
            }

            ViewData["ddlNhomQuyen"] = Json(ddl);

            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            return ValidateView(QuyenXem, "admin-nguoi-dung");
        }
        [Authorize]
        public JsonResult admin_nguoi_dung_json(string idNhomCap, string idCocau, string suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 52;
            string err = "";
            List<SYS_CoCauBase> list = new List<SYS_CoCauBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                byte? idNhomCapNew = null;
                System.Nullable<long> iDChaNew = null;
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(idNhomCap)) idNhomCapNew = Helper.ToByte(idNhomCap);
                if (!string.IsNullOrEmpty(idCocau)) iDChaNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSCoCau(idNhomCapNew, iDChaNew, suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        //=================================================
        [Authorize]
        public IActionResult co_cau_to_chuc()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionToChucThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionToChucXoa);
            ViewData["QuyenImport"] = 5;
            ViewData["QuyenExport"] = 5;
            //ViewData["QuyenDongBo"] = Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            int IDChucNang = 10;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["co-cau-to-chuc"] = "class=active";
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            return ValidateView(QuyenXem, "co-cau-to-chuc");
        }
        [Authorize]
        public JsonResult co_cau_to_chuc_json(string idNhomCap, string idCocau, string suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 10;
            string err = "";
            List<SYS_CoCauBase> list = new List<SYS_CoCauBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                byte? idNhomCapNew = null;
                System.Nullable<long> iDChaNew = null;
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(idNhomCap)) idNhomCapNew = Helper.ToByte(idNhomCap);
                if (!string.IsNullOrEmpty(idCocau)) iDChaNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSCoCau(idNhomCapNew, iDChaNew, suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult pop_dong_bo_co_cau(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int QuyenDongBo = 1;// Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            ViewData["QuyenDongBo"] = QuyenDongBo;
            int IDChucNang = 10;
            DTOBase b = new DTOBase();
            string err = "";
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenDongBo = 1;
            }
            return ValidateView(QuyenDongBo, "pop-dong-bo-co-cau");
        }
        private void BindUrlRefresh(ObjectAspUser user)
        {
            if (user.UserID == 0)
            {
                ViewData["urlRefresh"] = hrs_encrypt(user.UserName);
            }
        }
        [Authorize]
        public JsonResult DongBoCoCauJson(string username, string password, string suDung, string lastUpdatedDate)
        {
            DateTime DateTimeDongBo = DateTime.Now;
            var user = BaseUser();
            int QuyenDongBo = 1;// Helper.GetQuyen(user.ListQuyen, ActionToChucDongBo);
            int IDChucNang = 10;
            string err = "";
            string log = "";
            string path = "";
            int IDKhachHang = user.IDKhachHang;
            try
            {
                if (user.UserID > 0)
                {
                    username = GetPhanQuyenAcc();
                    password = GetPhanQuyenPass();
                }
                else IDKhachHang = -1;
                DTOBase b = new DTOBase();

                string token = "";
                var reqdata = new { reqdata = new { UserName = username, Password = password } };
                var objToken = JsonSerializer.Deserialize<ApiObjectLogin>(Helper.apiPost(GetApiToken(), JsonSerializer.Serialize(reqdata), token));

                var reqlistKH = new { request = lastUpdatedDate };
                var listKH = JsonSerializer.Deserialize<List<ApiObjectKhachHang>>(Helper.apiPost(GetApiDSKhachHang(), JsonSerializer.Serialize(reqlistKH), objToken.access_token));
                int iMaxKH = listKH.Count();
                for (int i = 0; i < iMaxKH; i++)
                {
                    SYS_KhachHang obj = new SYS_KhachHang();
                    obj.IDKhachHang = listKH[i].ID;
                    obj.Code = listKH[i].Code;
                    obj.Name = listKH[i].Name;
                    obj.Email = listKH[i].Email;
                    obj.IsDeleted = listKH[i].IsDeleted;
                    try
                    {
                        b.DongBo_KhachHang(obj, user, ref err);
                        System.Threading.Thread.Sleep(10);
                        if (i == 0 && user.UserID == 0 && obj.IDKhachHang > 0)
                        {
                            //UpdateUserLogin_IDKhachHang("IDKhachHang", obj.IDKhachHang);
                        }
                    }
                    catch (Exception ex)
                    {
                        err = ex.Message;
                    }
                }

                var reqlist = new { request = lastUpdatedDate, IDKhachHang = IDKhachHang };
                var list = JsonSerializer.Deserialize<List<ApiObjectCoCau>>(Helper.apiPost(GetApiDSCoCau(), JsonSerializer.Serialize(reqlist), objToken.access_token));
                int iMax = list.Count();
                ObjectPager pager = new ObjectPager();
                pager.idQuyen = QuyenDongBo;
                if (iMax > 0)
                {
                    for (int i = 0; i < iMax; i++)
                    {
                        err = "";
                        SYS_CoCau obj = new SYS_CoCau();
                        obj.DB_IDCoCau = list[i].ID;
                        obj.DB_IDCha = list[i].IDParent;
                        obj.MaCoCau = Helper.Trim(list[i].Code);
                        obj.IDKhachHang = list[i].IDKhachHang;
                        obj.TenCoCau = Helper.Trim(list[i].Name);
                        //obj.TenCoCauNgan = Helper.Trim(list[i].Name);
                        obj.MoTa = Helper.Trim(list[i].Remark);
                        obj.ThuTu = list[i].Sort;
                        obj.IsDelete = list[i].IsDeleted;
                        try
                        {
                            b.DongBo_CoCau(obj, pager, user, ref err);
                            if (!string.IsNullOrEmpty(err))
                                log += obj.MaCoCau + ": " + err + Environment.NewLine;
                            System.Threading.Thread.Sleep(10);
                        }
                        catch (Exception ex)
                        {
                            err = ex.Message;
                        }
                    }
                    b.DongBo_CoCauUpdateIDCha(IDKhachHang, ref err);
                    b.DongBo_CoCauSapXep(user, ref err);
                    IDKhachHang = list[0].IDKhachHang;
                }
                if (!string.IsNullOrEmpty(log)) path = Helper.WriteLog(user.UserID, "DongBoCoCau", log); else path = "";
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { path = path, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult pop_co_cau_to_chuc(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int ActionXem = ActionToChucXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionToChucThem);
            int IDChucNang = 10;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            ViewData["ID"] = 0;
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            var objData = LAY_CoCauToChucJson(id, ActionXem, user);
            ViewData["objData"] = objData;
            ViewData["SuDungTichHop"] = GetLabel_SuDung();
            ViewData["MaTichHop"] = GetLabel_MaTichHop();
            return ValidateView(QuyenXem, "pop-co-cau-to-chuc");
        }
        [Authorize]
        public JsonResult LUU_CoCauToChucJson(SYS_CoCau obj)
        {
            var user = BaseUser();
            int ActionThem = ActionToChucThem;
            int QuyenThem = Helper.GetQuyen(user.ListQuyen, ActionThem);
            int IDChucNang = 10;
            var objNew = new SYS_CoCau();
            objNew.IDCoCau = 0;
            string err = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                pager.idQuyen = ActionThem;
                DTOBase b = new DTOBase();
                b.LUU_CoCau(obj, pager, user, ref err);
                string ID = obj.IDCoCau.ToString();
                objNew.IDCoCau = obj.IDCoCau;
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { data = objNew, err = err };
            return Json(result);
        }
        [Authorize]
        public JsonResult XOA_CoCauToChucJson(string tmp, int idQuyen)
        {
            var user = BaseUser();
            int ActionXoa = ActionToChucXoa;
            int QuyenXoa = Helper.GetQuyen(user.ListQuyen, ActionXoa);
            int IDChucNang = 10;
            string err = "";
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = ActionXoa;
            if (!string.IsNullOrEmpty(tmp))
            {
                try
                {
                    DTOBase b = new DTOBase();
                    var arr1 = tmp.Trim(';').Split(';');
                    if (arr1.Length > 0)
                    {
                        for (int i = 0; i < arr1.Length; i++)
                        {
                            long? iDCoCau = Helper.ToInt64(arr1[i]);
                            if (iDCoCau != null)
                                err = b.sp_XOA_CoCau(iDCoCau, pager, user);
                        }
                    }

                }
                catch (Exception ex)
                {
                    err = ex.Message;
                }
            }
            var result = new { err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult co_cau_chuc_danh()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionChucDanhXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionChucDanhThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionChucDanhXoa);
            ViewData["QuyenImport"] = 5;
            ViewData["QuyenExport"] = 5;
            int IDChucNang = 11;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            long? idNhomCap = null;
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["co-cau-chuc-danh"] = "class=active";
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            return ValidateView(QuyenXem, "co-cau-chuc-danh");
        }
        [Authorize]
        public JsonResult co_cau_chuc_danh_json(string idCocau, string suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionChucDanhXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 11;
            string err = "";
            List<SYS_ChucDanhBase> list = new List<SYS_ChucDanhBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                long? iDChaNew = null;
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(idCocau)) iDChaNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSChucDanh(iDChaNew, suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult pop_dong_bo_chuc_danh(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int QuyenDongBo = 1;// Helper.GetQuyen(user.ListQuyen, ActionChucDanhDongBo);
            ViewData["QuyenDongBo"] = QuyenDongBo;
            int IDChucNang = 11;
            DTOBase b = new DTOBase();
            string err = "";
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenDongBo = 1;
            }
            return ValidateView(QuyenDongBo, "pop-dong-bo-chuc-danh");
        }
        [Authorize]
        public JsonResult DongBoChucDanhJson(string username, string password, string suDung, string lastUpdatedDate)
        {
            DateTime DateTimeDongBo = DateTime.Now;
            var user = BaseUser();
            int QuyenDongBo = 1;// Helper.GetQuyen(user.ListQuyen, ActionChucDanhDongBo);
            int IDChucNang = 11;
            string err = "";
            string log = "";
            string path = "";
            int IDKhachHang = user.IDKhachHang;
            try
            {
                if (user.UserID > 0)
                {
                    username = GetPhanQuyenAcc();
                    password = GetPhanQuyenPass();
                }
                else IDKhachHang = -1;
                string token = "";
                var reqdata = new { reqdata = new { UserName = username, Password = password } };
                var objToken = JsonSerializer.Deserialize<ApiObjectLogin>(Helper.apiPost(GetApiToken(), JsonSerializer.Serialize(reqdata), token));

                var reqlist = new { request = lastUpdatedDate, IDKhachHang = IDKhachHang };
                var list = JsonSerializer.Deserialize<List<ApiObjectChucDanh>>(Helper.apiPost(GetApiDSChucDanh(), JsonSerializer.Serialize(reqlist), objToken.access_token));
                int iMax = list.Count();
                ObjectPager pager = new ObjectPager();
                pager.idQuyen = QuyenDongBo;
                DTOBase b = new DTOBase();
                if (iMax > 0)
                {
                    for (int i = 0; i < iMax; i++)
                    {
                        err = "";
                        SYS_ChucDanh obj = new SYS_ChucDanh();
                        obj.DB_IDChucDanh = list[i].ID;
                        obj.DB_IDCha = list[i].IDParent;
                        obj.IDCoCau = list[i].IDDonVi;
                        obj.MaChucDanh = Helper.Trim(list[i].Code);
                        obj.IDKhachHang = list[i].IDKhachHang;
                        obj.TenChucDanh = Helper.Trim(list[i].Name);
                        //obj.TenChucDanhNgan = Helper.Trim(list[i].Name);
                        obj.LaCapTruong = list[i].LaTruongDonVi;
                        obj.IsDelete = list[i].IsDeleted;
                        try
                        {
                            b.DongBo_ChucDanh(obj, pager, user, ref err);
                            if (!string.IsNullOrEmpty(err))
                                log += obj.MaChucDanh + ": " + err + Environment.NewLine;
                            System.Threading.Thread.Sleep(10);
                        }
                        catch (Exception ex)
                        {
                            err = ex.Message;
                        }
                    }
                    b.DongBo_ChucDanhUpdateIDCha(IDKhachHang, ref err);
                    b.DongBo_ChucDanhSapXep(user, ref err);
                    IDKhachHang = list[0].IDKhachHang;
                }
                if (!string.IsNullOrEmpty(log)) path = Helper.WriteLog(user.UserID, "DongBoChucDanh", log); else path = "";
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }

            var result = new { path = path, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult pop_co_cau_chuc_danh(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int ActionXem = ActionChucDanhXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionChucDanhThem);
            int IDChucNang = 11;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            ViewData["ID"] = 0;
            long? idNhomCap = null;
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            ViewData["ddlChucDanh"] = chuc_danh_search_JsonDDL(null, null, ActionXem);
            var objData = LAY_CoCauChucDanhJson(id, ActionXem, user);
            ViewData["objData"] = objData;
            return ValidateView(QuyenXem, "pop-co-cau-chuc-danh");
        }
        [Authorize]
        public JsonResult LUU_CoCauChucDanhJson(SYS_ChucDanh obj)
        {
            var user = BaseUser();
            int ActionThem = ActionChucDanhThem;
            int QuyenThem = Helper.GetQuyen(user.ListQuyen, ActionThem);
            int IDChucNang = 11;
            var objNew = new SYS_ChucDanh();
            objNew.IDChucDanh = 0;
            string err = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                pager.idQuyen = ActionThem;
                DTOBase b = new DTOBase();
                b.LUU_ChucDanh(obj, pager, user, ref err);
                string ID = obj.IDChucDanh.ToString();
                objNew.IDChucDanh = obj.IDChucDanh;
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { data = objNew, err = err };
            return Json(result);
        }
        [Authorize]
        public JsonResult XOA_CoCauChucDanhJson(string tmp, int idQuyen)
        {
            var user = BaseUser();
            int ActionXoa = ActionChucDanhXoa;
            int QuyenXoa = Helper.GetQuyen(user.ListQuyen, ActionXoa);
            int IDChucNang = 11;
            string err = "";
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = ActionXoa;
            if (!string.IsNullOrEmpty(tmp))
            {
                try
                {
                    DTOBase b = new DTOBase();
                    var arr1 = tmp.Trim(';').Split(';');
                    if (arr1.Length > 0)
                    {
                        for (int i = 0; i < arr1.Length; i++)
                        {
                            long? iDChucDanh = Helper.ToInt64(arr1[i]);
                            if (iDChucDanh != null)
                                err = b.sp_XOA_ChucDanh(iDChucDanh, pager, user);
                        }
                    }

                }
                catch (Exception ex)
                {
                    err = ex.Message;
                }
            }
            var result = new { err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult co_cau_nhan_su()
        {
            var user = BaseUser();
            BindUrlRefresh(user);
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionNhanSuXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionNhanSuThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionNhanSuXoa);
            ViewData["QuyenImport"] = 5;
            ViewData["QuyenExport"] = 5;
            int IDChucNang = 12;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            DTOBase b = new DTOBase();
            long? idNhomCap = null;
            ViewData["ddlNhomCap"] = co_cau_nhom_cap_JsonDDL(ActionXem, true, ref idNhomCap);
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["co-cau-nhan-su"] = "class=active";
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenXem = 1;
            }
            return ValidateView(QuyenXem, "co-cau-nhan-su");
        }
        [Authorize]
        public JsonResult co_cau_nhan_su_json(string idNhomCap, string idCocau, string trangThai, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionNhanSuXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 12;
            string err = "";
            List<SYS_NhanSuBase> list = new List<SYS_NhanSuBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                byte? idNhomCapNew = null;
                System.Nullable<long> idCocauNew = null;
                byte? trangThaiNew = null;
                if (!string.IsNullOrEmpty(idNhomCap)) idNhomCapNew = Helper.ToByte(idNhomCap);
                if (!string.IsNullOrEmpty(idCocau)) idCocauNew = Helper.ToInt64(idCocau);
                if (!string.IsNullOrEmpty(trangThai)) trangThaiNew = Helper.ToByte(trangThai);

                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSNhanSu(idNhomCapNew, idCocauNew, trangThaiNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult pop_dong_bo_nhan_su(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int QuyenDongBo = 1;// Helper.GetQuyen(user.ListQuyen, ActionNhanSuDongBo);
            ViewData["QuyenDongBo"] = QuyenDongBo;
            int IDChucNang = 12;
            DTOBase b = new DTOBase();
            string err = "";
            if (user.UserID == 0)
            {
                ViewData["QuyenDongBo"] = 1;
                QuyenDongBo = 1;
            }
            return ValidateView(QuyenDongBo, "pop-dong-bo-nhan-su");
        }
        [Authorize]
        public JsonResult DongBoNhanSuJson(string username, string password, string suDung, string lastUpdatedDate)
        {
            DateTime DateTimeDongBo = DateTime.Now;
            var user = BaseUser();
            int QuyenDongBo = 1;// Helper.GetQuyen(user.ListQuyen, ActionNhanSuDongBo);
            int IDChucNang = 12;
            string err = "";
            string path = "";
            string log = "";
            int IDKhachHang = user.IDKhachHang;
            try
            {
                if (user.UserID > 0)
                {
                    username = GetPhanQuyenAcc();
                    password = GetPhanQuyenPass();
                }
                else IDKhachHang = -1;
                string token = "";
                var reqdata = new { reqdata = new { UserName = username, Password = password } };
                var objToken = JsonSerializer.Deserialize<ApiObjectLogin>(Helper.apiPost(GetApiToken(), JsonSerializer.Serialize(reqdata), token));

                var reqlist = new { request = lastUpdatedDate, IDKhachHang = IDKhachHang };
                var list = JsonSerializer.Deserialize<List<ApiObjectNhanSu>>(Helper.apiPost(GetApiDSNhanSu(), JsonSerializer.Serialize(reqlist), objToken.access_token));
                int iMax = list.Count();
                ObjectPager pager = new ObjectPager();
                pager.idQuyen = QuyenDongBo;
                path = GetUrlAnhNhanSu().Trim('/');
                DTOBase b = new DTOBase();
                if (iMax > 0)
                {
                    err = "";
                    for (int i = 0; i < iMax; i++)
                    {
                        SYS_NhanSu obj = new SYS_NhanSu();
                        obj.DB_IDNhanSu = list[i].ID;
                        obj.DB_UserName = list[i].Username;
                        obj.IDCoCau = list[i].IDDonVi;
                        obj.IDChucDanh = list[i].IDChucDanh;
                        obj.MaNhanSu = Helper.Trim(list[i].Code);
                        obj.Email = Helper.Trim(list[i].Email);
                        obj.IDKhachHang = list[i].IDKhachHang;
                        obj.NgayHieuLuc = Helper.TodateVN(list[i].NgayHieuLuc);
                        obj.NgayHetHan = Helper.TodateVN(list[i].NgayHetHan);

                        try
                        {
                            string sHo = Helper.Trim(list[i].Ho);
                            string sTenDem = Helper.Trim(list[i].TenDem);
                            string sTen = Helper.Trim(list[i].Ten);
                            obj.HoVaTen = sHo + " " + sTenDem + " " + sTen;
                        }
                        catch (Exception ex)
                        {
                            string tmpErr = ex.Message;
                        }
                        //obj.HoVaTen = (Helper.Trim(list[i].Ho) + " " + Helper.Trim(list[i].TenDem).Trim(' ')) + " " + Helper.Trim(list[i].Ten);
                        //obj.TenNhanSuNgan = list[i].Ten;
                        if (!string.IsNullOrEmpty(list[i].ImageSmall))
                            obj.AnhNhanSu = path + "/" + list[i].ImageSmall.Trim('/');
                        else obj.AnhNhanSu = null;

                        //list[i].TinhTrang: 0 - Tạo Mới, 1 - Đang làm việc, 2 - Đã nghỉ việc
                        switch (list[i].TinhTrang)
                        {
                            case 0:
                            case 1:
                                obj.TrangThai = 1; break;//Đang làm việc
                            default:
                                obj.TrangThai = 2; break;//Đã nghỉ việc
                        }
                        obj.IsDelete = list[i].IsDeleted;
                        try
                        {
                            b.DongBo_NhanSu(obj, user, ref err);
                            if (!string.IsNullOrEmpty(err))
                                log += obj.MaNhanSu + ": " + err + Environment.NewLine;
                            System.Threading.Thread.Sleep(10);
                        }
                        catch (Exception ex)
                        {
                            err = ex.Message;
                        }
                    }
                    IDKhachHang = list[0].IDKhachHang;
                }
                if (!string.IsNullOrEmpty(log)) path = Helper.WriteLog(user.UserID, "DongBoNhanSu", log); else path = "";
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }

            var result = new { path = path, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult pop_co_cau_nhan_su(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int ActionXem = ActionNhanSuXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionNhanSuThem);
            int IDChucNang = 12;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            ViewData["ID"] = 0;
            long? idNhomCap = null;
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["ddlToChuc"] = co_cau_to_chuc_JsonDDL(idNhomCap, ActionXem);
            ViewData["ddlTrangThai"] = trang_thai_nhan_su_JsonDDL(ActionXem);
            ViewData["ddlChucDanh"] = chuc_danh_search_JsonDDL(null, null, ActionXem);
            var objData = LAY_CoCauNhanSuJson(id, ActionXem, user);
            ViewData["objData"] = objData;
            return ValidateView(QuyenXem, "pop-co-cau-nhan-su");
        }
        [Authorize]
        public JsonResult LUU_CoCauNhanSuJson(SYS_NhanSu obj)
        {
            var user = BaseUser();
            int ActionThem = ActionNhanSuThem;
            int QuyenThem = Helper.GetQuyen(user.ListQuyen, ActionThem);
            int IDChucNang = 12;
            var objNew = new SYS_NhanSu();
            objNew.IDNhanSu = 0;
            string err = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                pager.idQuyen = ActionThem;
                DTOBase b = new DTOBase();
                b.LUU_NhanSu(obj, pager, user, ref err);
                string ID = obj.IDNhanSu.ToString();
                objNew.IDNhanSu = obj.IDNhanSu;
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { data = objNew, err = err };
            return Json(result);
        }
        [Authorize]
        public JsonResult XOA_CoCauNhanSuJson(string tmp, int idQuyen)
        {
            var user = BaseUser();
            int ActionXoa = ActionNhanSuXoa;
            int QuyenXoa = Helper.GetQuyen(user.ListQuyen, ActionXoa);
            int IDChucNang = 12;
            string err = "";
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = ActionXoa;
            if (!string.IsNullOrEmpty(tmp))
            {
                try
                {
                    DTOBase b = new DTOBase();
                    var arr1 = tmp.Trim(';').Split(';');
                    if (arr1.Length > 0)
                    {
                        for (int i = 0; i < arr1.Length; i++)
                        {
                            long? IDNhanSu = Helper.ToInt64(arr1[i]);
                            if (IDNhanSu != null)
                                err = b.sp_XOA_NhanSu(IDNhanSu, pager, user);
                        }
                    }

                }
                catch (Exception ex)
                {
                    err = ex.Message;
                }
            }
            var result = new { err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult co_cau_nhom_cap()
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;

            int ActionXem = ActionNhomCapXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionNhomCapThem);
            ViewData["QuyenXoa"] = Helper.GetQuyen(user.ListQuyen, ActionNhomCapXoa);
            int IDChucNang = 13;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            ViewData["co-cau-nhom-cap"] = "class=active";
            return ValidateView(QuyenXem, "co-cau-nhom-cap");
        }
        [Authorize]
        public JsonResult co_cau_nhom_cap_json(string suDung, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = ActionNhomCapXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            int IDChucNang = 13;
            string err = "";
            List<TW_NhomCapBase> list = new List<TW_NhomCapBase>();
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                bool? suDungNew = null;
                if (!string.IsNullOrEmpty(suDung))
                {
                    if (suDung == "1") suDungNew = true;
                    if (suDung == "0") suDungNew = false;
                }
                pager.pageSize = b.GetPageSize();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);

                list = b.LAY_DSNhomCap(suDungNew, pager, user, ref err);
                if (list.Count > 0) { pager.totalRow = list[0].TotalRow; }
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { list = list, pager = pager, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult pop_co_cau_nhom_cap(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int ActionXem = ActionNhomCapXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            ViewData["QuyenThem"] = Helper.GetQuyen(user.ListQuyen, ActionNhomCapThem);
            int IDChucNang = 13;
            ViewData["QuyenXem"] = QuyenXem; ViewData["ActionXem"] = ActionXem;
            ViewData["ID"] = 0;
            DTOBase b = new DTOBase();
            ViewData["PageTitle"] = GetTenChucNang(IDChucNang);
            var objData = LAY_CoCauNhomCapJson(id, ActionXem, user);
            ViewData["objData"] = objData;
            return ValidateView(QuyenXem, "pop-co-cau-nhom-cap");
        }
        [Authorize]
        public IActionResult pop_doi_mat_khau(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            ViewData["ID"] = 0;
            return ValidateView(1, "pop-doi-mat-khau");
        }
        [Authorize]
        public JsonResult LUU_DoiMatKhauJson(string passHienTai, string passMoi)
        {
            var user = BaseUser();
            user.PassHienTai = passHienTai;
            user.PassMoi = passMoi;
            string err = "";
            int iResult = 0;
            try
            {
                DTOBase b = new DTOBase();
                iResult = b.LUU_DoiMatKhau(user, ref err);
                if (iResult == -1) err = "Sai mật khẩu";
                if (iResult == -2) err = "Sai thông tin người dùng";
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { err = err };
            return Json(result);
        }
        [Authorize]
        public JsonResult LUU_CoCauNhomCapJson(TW_NhomCap obj)
        {
            var user = BaseUser();
            int ActionThem = ActionNhomCapThem;
            int QuyenThem = Helper.GetQuyen(user.ListQuyen, ActionThem);
            int IDChucNang = 13;
            var objNew = new TW_NhomCap();
            objNew.IDNhomCap = 0;
            string err = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                pager.idQuyen = ActionThem;
                DTOBase b = new DTOBase();
                b.LUU_NhomCap(obj, pager, user, ref err);
                string ID = obj.IDNhomCap.ToString();
                objNew.IDNhomCap = obj.IDNhomCap;
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { data = objNew, err = err };
            return Json(result);
        }
        [Authorize]
        public JsonResult XOA_CoCauNhomCapJson(string tmp, int idQuyen)
        {
            var user = BaseUser();
            int ActionXoa = ActionNhomCapXoa;
            int QuyenXoa = Helper.GetQuyen(user.ListQuyen, ActionXoa);
            int IDChucNang = 13;
            string err = "";
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = ActionXoa;
            if (!string.IsNullOrEmpty(tmp))
            {
                try
                {
                    DTOBase b = new DTOBase();
                    var arr1 = tmp.Trim(';').Split(';');
                    if (arr1.Length > 0)
                    {
                        for (int i = 0; i < arr1.Length; i++)
                        {
                            long? IDNhanSu = Helper.ToInt64(arr1[i]);
                            if (IDNhanSu != null)
                                err = b.sp_XOA_NhomCap(IDNhanSu, pager, user);
                        }
                    }

                }
                catch (Exception ex)
                {
                    err = ex.Message;
                }
            }
            var result = new { err = err };
            return Json(result);
        }
        public JsonResult chu_the_chi_tieu_JsonDDL(long? idNhomCap, int idQuyen, int iType)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = idQuyen;
            var list = b.LAY_DDL_CoCau(idNhomCap, pager, user);
            List<ObjectDDL> ddl = new List<ObjectDDL>();
            ObjectDDL obj;
            //0:Cá nhân0
            if (iType == 0)
            {
                obj = new ObjectDDL();
                obj.id = 0;
                obj.text = "Cá nhân";
                ddl.Add(obj);
            }

            for (int i = 0; i < list.Count; i++)
            {
                obj = new ObjectDDL();
                obj.id = list[i].IDCoCau;
                if (list[i].CapBac > 0)
                {
                    obj.text = "";
                    for (int j = 1; j < list[i].CapBac; j++)
                    {
                        obj.text = obj.text + "--";
                    }
                    obj.text = obj.text + " " + list[i].MaCoCau + " - " + list[i].TenCoCau;
                }
                else obj.text = list[i].TenCoCau;

                ddl.Add(obj);
            }
            return Json(ddl);
        }

        public JsonResult co_cau_to_chuc_JsonDDL(long? idNhomCap, int idQuyen)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = idQuyen;
            var list = b.LAY_DDL_CoCau(idNhomCap, pager, user);
            List<ObjectDDL> ddl = new List<ObjectDDL>();
            ObjectDDL obj;
            for (int i = 0; i < list.Count; i++)
            {
                obj = new ObjectDDL();
                obj.id = list[i].IDCoCau;
                if (list[i].CapBac > 0)
                {
                    obj.text = "";
                    for (int j = 1; j < list[i].CapBac; j++)
                    {
                        obj.text = obj.text + "--";
                    }
                    obj.text = obj.text + " " + list[i].MaCoCau + " - " + list[i].TenCoCau;
                }
                else obj.text = list[i].TenCoCau;

                ddl.Add(obj);
            }
            return Json(ddl);
        }
        public JsonResult co_cau_to_chuc_con_JsonDDL(long? idCoCau, bool bCha, int idQuyen)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = idQuyen;
            var list = b.LAY_DDL_CoCauCon(idCoCau, pager, user);
            List<ObjectCoCauVaNhanSuDDL> ddl = new List<ObjectCoCauVaNhanSuDDL>();
            ObjectCoCauVaNhanSuDDL obj;
            int iMin = 0;
            if (!bCha) iMin = 1;
            for (int i = iMin; i < list.Count; i++)
            {
                obj = new ObjectCoCauVaNhanSuDDL();
                obj.id = (long)list[i].IDCoCau;
                if (list[i].CapBac > 0)
                {
                    obj.text = "";
                    for (int j = 1; j < list[i].CapBac; j++)
                    {
                        obj.text = obj.text + "--";
                    }
                    obj.text = obj.text + " " + list[i].MaCoCau + " - " + list[i].TenCoCau;
                }
                else obj.text = list[i].TenCoCau;
                obj.idNS = list[i].IDNhanSu;
                obj.textNS = list[i].MaNhanSu + " - " + list[i].HoVaTen;
                obj.idCD = list[i].IDChucDanh;
                obj.textCD = list[i].MaChucDanh + " - " + list[i].TenChucDanh;
                obj.url = list[i].AnhNhanSu == null ? "." : list[i].AnhNhanSu;
                ddl.Add(obj);
            }
            return Json(ddl);
        }
        public JsonResult trang_thai_nhan_su_JsonDDL(int idQuyen)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();

            ObjectPager pager = new ObjectPager();
            pager.idQuyen = idQuyen;
            var list = b.LAY_DDL_TrangThaiNhanSu(pager, user);
            List<ObjectDDL> ddl = new List<ObjectDDL>();
            ObjectDDL obj;
            for (int i = 0; i < list.Count; i++)
            {
                obj = new ObjectDDL();
                obj.id = (long)list[i].IDTrangThaiNhanSu;
                obj.text = list[i].TenTrangThaiNhanSu;
                ddl.Add(obj);
            }
            return Json(ddl);
        }
        public JsonResult co_cau_nhom_cap_JsonDDL(int idQuyen, bool isLoadAll, ref long? idNhomCap)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();

            ObjectPager pager = new ObjectPager();
            pager.idQuyen = idQuyen;
            var list = b.LAY_DDL_NhomCap(pager, user);
            List<ObjectDDL> ddl = new List<ObjectDDL>();
            ObjectDDL obj;
            for (int i = 0; i < list.Count; i++)
            {
                obj = new ObjectDDL();
                obj.id = list[i].IDNhomCap;
                obj.text = list[i].TenNhomCap;
                ddl.Add(obj);
                if (!isLoadAll)
                    if (i == 0 && idNhomCap == null) idNhomCap = obj.id;
            }
            return Json(ddl);
        }

        public JsonResult nhan_su_search_AllChucDanh_JsonDDL(string listID, string keyword, int idQuyen)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();

            ObjectPager pager = new ObjectPager();
            pager.idQuyen = idQuyen;
            if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
            var list = b.sp_LAY_DLL_NhanSuSearch_AllChucDanh(listID, pager, user);
            List<ObjectNhanSuAllChucDanhDDL> ddl = new List<ObjectNhanSuAllChucDanhDDL>();
            ObjectNhanSuAllChucDanhDDL obj;
            for (int i = 0; i < list.Count; i++)
            {
                obj = new ObjectNhanSuAllChucDanhDDL();
                obj.id = list[i].IDNhanSu.ToString() + "_" + list[i].IDChucDanh;
                obj.text = list[i].MaNhanSu + " - " + list[i].HoVaTen;
                //obj.maNS = list[i].MaNhanSu;
                obj.url = list[i].AnhNhanSu == null ? "." : list[i].AnhNhanSu;
                obj.idCD = list[i].IDChucDanh;
                if (!Helper.isTrue(list[i].ChucDanhChinh))
                    obj.tenCD = list[i].TenChucDanh + " (Kiêm nhiệm)";
                else obj.tenCD = list[i].TenChucDanh;
                obj.idCC = list[i].IDCoCau;
                obj.tenCC = list[i].TenCoCau;
                ddl.Add(obj);
            }
            return Json(ddl);
        }
        public JsonResult nhan_su_search_JsonDDL(string listID, string keyword, int idQuyen)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();

            ObjectPager pager = new ObjectPager();
            pager.idQuyen = idQuyen;
            if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
            var list = b.sp_LAY_DDL_NhanSuSearch(listID, pager, user);
            List<ObjectNhanSuDDL> ddl = new List<ObjectNhanSuDDL>();
            ObjectNhanSuDDL obj;
            for (int i = 0; i < list.Count; i++)
            {
                obj = new ObjectNhanSuDDL();
                obj.id = list[i].IDNhanSu;
                obj.text = list[i].MaNhanSu + " - " + list[i].HoVaTen;
                //obj.maNS = list[i].MaNhanSu;
                obj.url = list[i].AnhNhanSu == null ? "." : list[i].AnhNhanSu;
                obj.idCD = list[i].IDChucDanh;
                obj.tenCD = list[i].TenChucDanh;
                obj.idCC = list[i].IDCoCau;
                obj.tenCC = list[i].TenCoCau;
                ddl.Add(obj);
            }
            return Json(ddl);
        }
        public JsonResult nhan_su_searchFull_JsonDDL(string listID, string keyword, int idQuyen)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();

            ObjectPager pager = new ObjectPager();
            pager.idQuyen = idQuyen;
            if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
            var list = b.sp_LAY_DLL_NhanSuSearchFull(listID, pager, user);
            List<ObjectNhanSuDDL> ddl = new List<ObjectNhanSuDDL>();
            ObjectNhanSuDDL obj;
            for (int i = 0; i < list.Count; i++)
            {
                obj = new ObjectNhanSuDDL();
                obj.id = list[i].IDNhanSu;
                obj.text = list[i].MaNhanSu + " - " + list[i].HoVaTen;
                //obj.maNS = list[i].MaNhanSu;
                obj.url = list[i].AnhNhanSu == null ? "." : list[i].AnhNhanSu;
                obj.idCD = list[i].IDChucDanh;
                obj.tenCD = list[i].TenChucDanh;
                obj.idCC = list[i].IDCoCau;
                obj.tenCC = list[i].TenCoCau;
                ddl.Add(obj);
            }
            return Json(ddl);
        }
        public JsonResult nhan_su_searchAdvance_JsonDDL(string listID, long? IDCoCau, long? IDChucDanh, string keyword, int idQuyen)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();

            ObjectPager pager = new ObjectPager();
            pager.idQuyen = idQuyen;
            if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
            var list = b.sp_LAY_DLL_NhanSuSearchAdvance(listID, IDCoCau, IDChucDanh, pager, user);
            List<ObjectNhanSuDDL> ddl = new List<ObjectNhanSuDDL>();
            ObjectNhanSuDDL obj;
            for (int i = 0; i < list.Count; i++)
            {
                obj = new ObjectNhanSuDDL();
                obj.id = list[i].IDNhanSu;
                obj.text = list[i].HoVaTen;
                obj.maNS = list[i].MaNhanSu;
                obj.url = list[i].AnhNhanSu == null ? "." : list[i].AnhNhanSu;
                obj.idCD = list[i].IDChucDanh;
                //obj.tenCD = list[i].TenChucDanh;
                if (!Helper.isTrue(list[i].ChucDanhChinh))
                    obj.tenCD = list[i].TenChucDanh + " (Kiêm nhiệm)";
                else obj.tenCD = list[i].TenChucDanh;

                obj.idCC = list[i].IDCoCau;
                obj.tenCC = list[i].TenCoCau;
                ddl.Add(obj);
            }
            return Json(ddl);
        }
        public JsonResult chuc_danh_search_JsonDDL(string id, string keyword, int idQuyen)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();
            long? idCoCauNew = null;
            ObjectPager pager = new ObjectPager();
            if (!string.IsNullOrEmpty(id)) idCoCauNew = Helper.ToInt64(id);
            pager.idQuyen = idQuyen;
            if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
            var list = b.sp_LAY_DDL_ChucDanhSearch(idCoCauNew, pager, user);
            List<Object2DDL> ddl = new List<Object2DDL>();
            Object2DDL obj;
            for (int i = 0; i < list.Count; i++)
            {
                obj = new Object2DDL();
                obj.id = list[i].IDChucDanh;
                obj.text = list[i].MaChucDanh + " - " + list[i].TenChucDanh;
                obj.des = list[i].TenCoCau;
                ddl.Add(obj);
            }
            return Json(ddl);
        }
        public JsonResult chuc_danh_nhan_su_JsonDDL(string id, int idQuyen)
        {
            var user = BaseUser();
            DTOBase b = new DTOBase();
            long? idNhanSu = null;
            ObjectPager pager = new ObjectPager();
            if (!string.IsNullOrEmpty(id)) idNhanSu = Helper.ToInt64(id);
            pager.idQuyen = idQuyen;
            var list = b.sp_LAY_DLL_ChucDanhNhanSu(idNhanSu, pager, user);
            List<Object2DDL> ddl = new List<Object2DDL>();
            Object2DDL obj;
            for (int i = 0; i < list.Count; i++)
            {
                obj = new Object2DDL();
                obj.id = list[i].IDChucDanh;
                if (list[i].KiemNhiem == "0")
                    obj.text = list[i].MaChucDanh + " - " + list[i].TenChucDanh;
                else obj.text = "[KN] - " + list[i].MaChucDanh + " - " + list[i].TenChucDanh;
                obj.des = list[i].TenCoCau;
                ddl.Add(obj);
            }
            return Json(ddl);
        }
        public JsonResult LAY_CoCauToChucJson(string id, int idQuyen, ObjectAspUser user)
        {
            var objNew = new SYS_CoCau();
            if (string.IsNullOrEmpty(id))
            {
                objNew.IDCoCau = 0;
                objNew.MaCoCau = "";
                objNew.SuDung = true;
                objNew.IDNhomCap = null;
            }
            long? idNew = null;
            string err = "";
            int iUpdate = 0;
            ObjectPager pager = new ObjectPager();
            try
            {
                pager.idQuyen = idQuyen;
                if (!string.IsNullOrEmpty(id)) idNew = Helper.ToInt64(id);
                DTOBase b = new DTOBase();
                if (idNew != null) objNew = b.LAY_CoCau(idNew, pager, user, ref iUpdate, ref err);
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { data = objNew, iUpdate = iUpdate, err = err };
            return Json(result);
        }
        public JsonResult LAY_CoCauChucDanhJson(string id, int idQuyen, ObjectAspUser user)
        {
            var objNew = new SYS_ChucDanh();
            if (string.IsNullOrEmpty(id))
            {
                objNew.IDChucDanh = 0;
                objNew.MaChucDanh = "";
                objNew.SuDung = true;
            }
            long? idNew = null;
            string err = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                pager.idQuyen = idQuyen;
                if (!string.IsNullOrEmpty(id)) idNew = Helper.ToInt64(id);
                DTOBase b = new DTOBase();
                if (idNew != null) objNew = b.LAY_ChucDanh(idNew, pager, user, ref err);
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { data = objNew, err = err };
            return Json(result);
        }
        public JsonResult LAY_CoCauNhanSuJson(string id, int idQuyen, ObjectAspUser user)
        {
            var objNew = new SYS_NhanSuOne();
            if (string.IsNullOrEmpty(id))
            {
                objNew.IDNhanSu = 0;
                objNew.MaNhanSu = "";
                objNew.TrangThai = 1;
            }
            long? idNew = null;
            string err = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                pager.idQuyen = idQuyen;
                if (!string.IsNullOrEmpty(id)) idNew = Helper.ToInt64(id);
                DTOBase b = new DTOBase();
                if (idNew != null) objNew = b.LAY_NhanSu(idNew, pager, user, ref err);

            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { data = objNew, err = err };
            return Json(result);
        }
        public JsonResult LAY_CoCauNhomCapJson(string id, int idQuyen, ObjectAspUser user)
        {
            var objNew = new TW_NhomCap();
            if (string.IsNullOrEmpty(id))
            {
                objNew.IDNhomCap = 0;
                objNew.MaNhomCap = "";
                objNew.SuDung = true;
            }
            long? idNew = null;
            string err = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                pager.idQuyen = idQuyen;
                if (!string.IsNullOrEmpty(id)) idNew = Helper.ToInt64(id);
                DTOBase b = new DTOBase();
                if (idNew != null) objNew = b.LAY_NhomCap(idNew, pager, user, ref err);
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { data = objNew, err = err };
            return Json(result);
        }

        #region SignalR
        private IHubContext<ProgressHub> HubContext { get; set; }
        private readonly IQueue _queue;

        public IActionResult _test()
        {
            _queue.QueueAsyncTask(async () =>
            {
                for (int i = 0; i <= 100; i += 5)
                {
                    Debug.WriteLine($"Background job progress: {i}");

                    await Task.Delay(100);
                }
            });

            return View();
        }

        public HomeController(IHubContext<ProgressHub> hubcontext, IQueue queue)
        {
            HubContext = hubcontext;
            _queue = queue;
        }

        public async Task<JsonResult> LongRunningProcess(string connectionId)
        {
            //THIS COULD BE SOME LIST OF DATA

            ProgressHub functions = new ProgressHub();

            await functions.SendProgress("Process in progress...", connectionId);

            return Json("OK");
        }

        public string getProgress(string connectionId)
        {
            _queue.QueueAsyncTask(async () =>
            {
                int itemsCount = 5;

                for (int i = 0; i <= itemsCount; i++)
                {
                    //SIMULATING SOME TASK
                    Thread.Sleep(500);

                    var percentage = (i * 100) / itemsCount;

                    await HubContext.Clients.Client(connectionId).SendAsync("AddProgress", "Uploading...", percentage + "%");
                }
            });

            return "Done after response";
        }

        [HttpPost]
        public IActionResult StartProgress()
        {
            string jobId = Guid.NewGuid().ToString("N");
            _queue.QueueAsyncTask(() => PerformBackgroundJob(jobId));

            return RedirectToAction("Progress", new { jobId });
        }

        public IActionResult Progress(string jobId)
        {
            ViewBag.JobId = jobId;

            return View();
        }

        private async Task PerformBackgroundJob(string jobId)
        {
            int total = 100;

            for (int i = 0; i <= total; i += 5)
            {
                // TODO: report progress with SignalR
                var percentage = (i * 100) / total;

                await HubContext.Clients.Group(jobId).SendAsync("progress", percentage);

                await HubContext.Clients.Group(jobId).SendAsync("AddProgress", "Uploading...", percentage + "%");

                await Task.Delay(100);
            }
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
        #endregion;

        #region Import/Export
        [Authorize]
        public IActionResult pop_import_co_cau_to_chuc(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int QuyenImport = 5;// Helper.GetQuyen(user.ListQuyen, ActionMucTieuImport);
            ViewData["QuyenImport"] = QuyenImport;
            return ValidateView(QuyenImport, "pop-import-co-cau-to-chuc");
        }
        [HttpPost]
        public ActionResult import_co_cau_to_chuc_upload_json(IFormFile file)
        {
            var user = BaseUser();
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = 1;// ActionMucTieuImport;
            string err = "";
            string path = "";
            try
            {
                if (file != null)
                {
                    var sTime = user.UserID + "_" + DateTime.Now.ToString("yyyyMMddHHmmss");
                    path = "uploads/" + sTime + "_" + file.FileName;
                    using (var stream = new FileStream(path, FileMode.Create))
                    {
                        file.CopyTo(stream);
                    }
                    //Read file
                    path = Helper.Import_CoCau(path, pager, user, ref err);
                    // do something
                }
            }
            catch (Exception ex)
            {
                err = ex.ToString();
            }

            var result = new { path = path, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult pop_import_co_cau_chuc_danh(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int QuyenImport = 5;// Helper.GetQuyen(user.ListQuyen, ActionMucTieuImport);
            ViewData["QuyenImport"] = QuyenImport;
            return ValidateView(QuyenImport, "pop-import-co-cau-chuc-danh");
        }
        [HttpPost]
        public ActionResult import_co_cau_chuc_danh_upload_json(IFormFile file)
        {
            var user = BaseUser();
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = 1;// ActionMucTieuImport;
            string err = "";
            string path = "";
            try
            {
                if (file != null)
                {
                    var sTime = user.UserID + "_" + DateTime.Now.ToString("yyyyMMddHHmmss");
                    path = "uploads/" + sTime + "_" + file.FileName;
                    using (var stream = new FileStream(path, FileMode.Create))
                    {
                        file.CopyTo(stream);
                    }
                    //Read file
                    path = Helper.Import_ChucDanh(path, pager, user, ref err);
                    // do something
                }
            }
            catch (Exception ex)
            {
                err = ex.ToString();
            }

            var result = new { path = path, err = err };
            return Json(result);
        }
        [Authorize]
        public IActionResult pop_import_co_cau_nhan_su(string id)
        {
            var user = BaseUser();
            var dUser = getDefaultUser(user); ViewData["dUser"] = dUser;
            int QuyenImport = 5;// Helper.GetQuyen(user.ListQuyen, ActionMucTieuImport);
            ViewData["QuyenImport"] = QuyenImport;
            return ValidateView(QuyenImport, "pop-import-co-cau-nhan-su");
        }
        [HttpPost]
        public ActionResult import_co_cau_nhan_su_upload_json(IFormFile file)
        {
            var user = BaseUser();
            ObjectPager pager = new ObjectPager();
            pager.idQuyen = 1;// ActionMucTieuImport;
            string err = "";
            string path = "";
            try
            {
                if (file != null)
                {
                    var sTime = user.UserID + "_" + DateTime.Now.ToString("yyyyMMddHHmmss");
                    path = "uploads/" + sTime + "_" + file.FileName;
                    using (var stream = new FileStream(path, FileMode.Create))
                    {
                        file.CopyTo(stream);
                    }
                    //Read file
                    path = Helper.Import_NhanSu(path, pager, user, ref err);
                    // do something
                }
            }
            catch (Exception ex)
            {
                err = ex.ToString();
            }

            var result = new { path = path, err = err };
            return Json(result);
        }
        [Authorize]
        public JsonResult export_co_cau_to_chuc_json(byte? idNhomCap, long? idCocau, bool? suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = 1;// ActionTongHopDanhGiaXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            string err = "";
            string path = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                pager.pageSize = 100000;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                var list = b.LAY_DSCoCau(idNhomCap, idCocau, suDung, pager, user, ref err);
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);
                path = Helper.export_CoCauToChuc(list, user, ref err);
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { path = path, err = err };
            return Json(result);
        }
        public JsonResult export_co_cau_chuc_danh_json(long? idCocau, bool? suDung, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = 1;// ActionTongHopDanhGiaXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            string err = "";
            string path = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                pager.pageSize = 100000;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                var list = b.LAY_DSChucDanh(idCocau, suDung, pager, user, ref err);
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);
                path = Helper.export_CoCauChucDanh(list, user, ref err);
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { path = path, err = err };
            return Json(result);
        }
        public JsonResult export_co_cau_nhan_su_json(byte? idNhomCap, long? idCocau, byte? trangThai, string keyword, string pageIndex, int idQuyen)
        {
            var user = BaseUser();
            int ActionXem = 1;// ActionTongHopDanhGiaXem;
            int QuyenXem = Helper.GetQuyen(user.ListQuyen, ActionXem);
            string err = "";
            string path = "";
            ObjectPager pager = new ObjectPager();
            try
            {
                DTOBase b = new DTOBase();
                pager.pageSize = 100000;
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                pager.idQuyen = ActionXem;
                pager.pageIndex = 1;
                pager.totalRow = 0;
                var list = b.LAY_DSNhanSu(idNhomCap, idCocau, trangThai, pager, user, ref err);
                if (!string.IsNullOrEmpty(pageIndex)) pager.pageIndex = Convert.ToInt32(pageIndex);
                path = Helper.export_CoCauNhanSu(list, user, ref err);
            }
            catch (Exception ex)
            {
                err = ex.Message;
            }
            var result = new { path = path, err = err };
            return Json(result);
        }
        #endregion
    }
}
