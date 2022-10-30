using System;
using Microsoft.AspNetCore.SignalR;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.IO;
using Microsoft.Extensions.Configuration;

using System.Text.Json;
using System.Net.Http;
using System.Net.Http.Headers;

using RestSharp;

using digiiTalentDTO;

namespace SignalR.Hubs
{
    public class ProgressHub : Hub
    {
        public async Task SendProgress(string progressMessage, string connectionId)
        {
            int itemsCount = 5;

            for (int i = 0; i <= itemsCount; i++)
            {
                //SIMULATING SOME TASK
                //Thread.Sleep(500);

                var percentage = (i * 100) / itemsCount;

                //CALLING A FUNCTION THAT CALCULATES PERCENTAGE AND SENDS THE DATA TO THE CLIENT
                //await Clients.Client(Context.ConnectionId).SendAsync("AddProgress", progressMessage, percentage + "%");
                await Clients.Client(connectionId).SendAsync("AddProgress", progressMessage, percentage + "%");
            }
        }

        public async Task SendMessage(string user, string message, string connectionId)
        {
            //await Clients.All.SendAsync("ReceiveMessage", user, message);
            //await Clients.Caller.SendAsync("ReceiveMessage", user, message);

            //await Clients.Client(Context.ConnectionId).SendAsync("ReceiveMessage", user, message);
            await Clients.Client(connectionId).SendAsync("ReceiveMessage", user, message);

            int itemsCount = 5;

            for (int i = 0; i <= itemsCount; i++)
            {
                //SIMULATING SOME TASK
                //Thread.Sleep(500);

                //CALLING A FUNCTION THAT CALCULATES PERCENTAGE AND SENDS THE DATA TO THE CLIENT
                await Clients.Client(Context.ConnectionId).SendAsync("progress", i);
            }
        }
        public async Task SendDanhGia(string user, string message, string connectionId)
        {
            //await Clients.All.SendAsync("ReceiveMessage", user, message);
            //await Clients.Caller.SendAsync("ReceiveMessage", user, message);

            //await Clients.Client(Context.ConnectionId).SendAsync("ReceiveMessage", user, message);
            //await Clients.Client(connectionId).SendAsync("ReceiveMessage", user, message);
            //string chuThe, long? idHTMT, long? idHTTS, long? idCoCau
            var arrUser = user.Split(';');
            var arr = message.Split(';');
            try
            {
                DTOBase b = new DTOBase();
                int iCount = arr.Length;
                //var message = chuThe + ";" + idHTMT + ";" + idHTTS + ";" + idCoCau;
                byte? chuThe = Helper.ToByte(arr[0]);
                long? idHTMTNew = Helper.ToInt64(arr[1]);
                long? idHTTSNew = Helper.ToInt64(arr[2]);
                long? idCoCauNew = null;
                long? idCoCauBPNew = null;
                string idCoCau = arr[3];
                List<ObjectID> listID = new List<ObjectID>();
                    


                byte? idNhomCapNew = null;
                byte? idLoaiTanSuatNew = null;
                long? idNguoiPhuTrachNew = null;
                byte? idLoaiMucTieuNew = null;
                byte? idTrangThaiDuyetNew = null;
                string keyword = null;

                int ActionTongHopDanhGiaSua = 555;

                ObjectPager pager = new ObjectPager();
                pager.pageSize = b.GetPageSize();
                if (!string.IsNullOrEmpty(keyword)) pager.keyword = keyword.Trim().ToLower();
                pager.idQuyen = ActionTongHopDanhGiaSua;
                pager.pageIndex = 1;
                pager.totalRow = 0;

                ObjectAspUser myUser = new ObjectAspUser();
                myUser.UserID = Convert.ToInt32(arrUser[0]);
                myUser.IDKhachHang = Convert.ToInt32(arrUser[1]);

                if (chuThe == 0)
                {
                    if (!string.IsNullOrEmpty(idCoCau))
                    {
                        ObjectID obj = new ObjectID();
                        obj.ID = Convert.ToInt64(idCoCau);
                        listID.Add(obj);
                    }
                    else
                    {
                        //Lấy danh sách ID đơn vị
                        listID = b.sp_LAY_DS_IDCoCau(idNhomCapNew, pager, myUser);
                    }
                }
                else
                {
                    //Lấy danh sách ID Nhân sự
                    listID = b.sp_LAY_DS_IDNhanSu(idCoCau, pager, myUser);
                }

                //var listLoaiMucTieu = b.sp_LAY_DDL_LoaiMucTieuTrucTiep(idHTMTNew, pager, myUser);
                int itemsCount = listID.Count;

                string err = "";
                string label = "Đánh giá ";
                if (chuThe == 0) label += "đơn vị: ";
                else label += "cá nhân: ";

                int iPercentage = 0;
                if (itemsCount == 0)
                {
                    await Clients.Client(Context.ConnectionId).SendAsync("progress", iPercentage, label + "0/" + itemsCount);
                }
                else
                {
                    for (int i = 0; i < itemsCount; i++)
                    {
                        //SIMULATING SOME TASK
                        if (chuThe == 0)
                        {
                            idCoCauNew = Helper.ToInt64(listID[i].ID);
                        }
                        else
                        {
                            idNguoiPhuTrachNew = Helper.ToInt64(listID[i].ID);
                        }

                        //Helper.export_DanhGia(listLoaiMucTieu, idHTMTNew, idNhomCapNew, idLoaiTanSuatNew, idHTTSNew, chuThe, 1, idCoCauNew, idNguoiPhuTrachNew, idLoaiMucTieuNew, pager, myUser, ref err);

                        //Thread.Sleep(20);
                        //CALLING A FUNCTION THAT CALCULATES PERCENTAGE AND SENDS THE DATA TO THE CLIENT

                        iPercentage = Convert.ToInt32((i + 1) * 100 / itemsCount);
                        await Clients.Client(Context.ConnectionId).SendAsync("progress", iPercentage, label + (i + 1).ToString() + "/" + itemsCount);
                    }
                }
            }
            catch (System.Exception ex)
            {

            }
            
            //for (int i = 0; i <= itemsCount; i++)
            //{
            //    //SIMULATING SOME TASK
            //    //Thread.Sleep(50);

            //    //CALLING A FUNCTION THAT CALCULATES PERCENTAGE AND SENDS THE DATA TO THE CLIENT
            //    await Clients.Client(Context.ConnectionId).SendAsync("progress", i, "taskB: " + i.ToString());
            //}
        }

        public async Task AssociateJob(string jobId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, jobId);
        }

        public string GetConnectionId()
        {
            return Context.ConnectionId;
        }

        public IConfigurationRoot GetConfiguration()
        {
            var builder = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory()).AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
            return builder.Build();
        }
        public IConfigurationRoot GetConfigurationLabel()
        {
            var builder = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory()).AddJsonFile("label.json", optional: true, reloadOnChange: true);
            return builder.Build();
        }

        public string GetTichHop_apiKey()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:apiKey"].ToString(); } catch { return ""; }
        }
        public int GetTichHop_NgayDauThang()
        {
            try { var config = GetConfigurationLabel(); return Convert.ToInt32(config["TichHop:NgayDauThang"]); } catch { return 1; }
        }
        public string GetTichHop_DoanhSo()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:DoanhSo"].ToString().Trim('/'); } catch { return ""; }
        }
        public string GetTichHop_DoanhThu()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:DoanhThu"].ToString().Trim('/'); } catch { return ""; }
        }
        public string GetTichHop_KhachHang()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:KhachHang"].ToString().Trim('/'); } catch { return ""; }
        }
        public string GetTichHop_SanPham()
        {
            try { var config = GetConfigurationLabel(); return config["TichHop:SanPham"].ToString().Trim('/'); } catch { return ""; }
        }
        public decimal GetTyLeGiam_DoanhSo()
        {
            try { var config = GetConfigurationLabel(); return Convert.ToDecimal(config["TichHop:TyLeGiam_DoanhSo"]); } catch { return 1; }
        }
        public decimal GetTyLeGiam_DoanhThu()
        {
            try { var config = GetConfigurationLabel(); return Convert.ToDecimal(config["TichHop:TyLeGiam_DoanhThu"]); } catch { return 1; }
        }
        public decimal GetTyLeGiam_KhachHang()
        {
            try { var config = GetConfigurationLabel(); return Convert.ToDecimal(config["TichHop:TyLeGiam_KhachHang"]); } catch { return 1; }
        }
        public decimal GetTyLeGiam_SanPham()
        {
            try { var config = GetConfigurationLabel(); return Convert.ToDecimal(config["TichHop:TyLeGiam_SanPham"]); } catch { return 1; }
        }
        public List<Object_CRM_CTL_Sale> apiGetSale(string url, string jsonValue)
        {
            List<Object_CRM_CTL_Sale> list = new List<Object_CRM_CTL_Sale>();
            try
            {
                var client = new RestClient(url);
                var request = new RestRequest("", Method.Get);
                request.AddHeader("Content-Type", "application/json");
                var sentData = System.Text.Encoding.UTF8.GetBytes(jsonValue);
                request.AddBody(sentData, "application/json");

                var response = client.Execute(request);
                if (!response.IsSuccessful)
                {
                    //Logic for handling unsuccessful response
                }
                string tmp = response.Content.Replace(@"\", "");
                list = JsonSerializer.Deserialize<List<Object_CRM_CTL_Sale>>(tmp);
                return list;
            }
            catch (Exception ex) { return list; }
        }
    }
}