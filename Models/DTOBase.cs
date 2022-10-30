using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using digiiTalentDTO;
using System.Data.Linq;
using System.IO;
using Microsoft.Extensions.Configuration;
using Zirpl.CalcEngine;
public class DTOBase
{
    public readonly IConfigurationRoot _config;
    public readonly string _connection;
    public DTOBase()
    {
        _config = GetConfiguration();
        _connection = _config.GetConnectionString("DbTeamW");
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
    public List<SYS_CoCauBase> LAY_DSCoCau(byte? idNhomCapNew, long? iDCha, bool? suDung, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        var list = new List<SYS_CoCauBase>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DSCoCau(idNhomCapNew, iDCha, suDung, pager.pageSize, pager.pageIndex, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang, false).ToList();
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return list;
        }
        return list;
    }
    public List<SYS_ChucDanhBase> LAY_DSChucDanh(long? iDCha, bool? suDung, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        var list = new List<SYS_ChucDanhBase>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DSChucDanh(iDCha, suDung, pager.pageSize, pager.pageIndex, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang, false).ToList();
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return list;
        }
        return list;
    }
    public List<SYS_NhanSuBase> LAY_DSNhanSu(byte? iDNhomCap, long? iDCha, byte? trangThai, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        var list = new List<SYS_NhanSuBase>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DSNhanSu(iDNhomCap, iDCha, trangThai, pager.pageSize, pager.pageIndex, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang, false).ToList();
                if (list != null)
                {
                    for (int i = 0; i < list.Count; i++)
                    {
                        list[i].sNgayHieuLuc = Helper.toNgayThangNam(list[i].NgayHieuLuc);
                        list[i].sNgayHetHan = Helper.toNgayThangNam(list[i].NgayHetHan);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return list;
        }
        return list;
    }
    public string sp_XOA_CoCau(long? iDCoCau, ObjectPager pager, ObjectAspUser user)
    {
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                DTO.sp_XOA_CoCau(iDCoCau, user.IDKhachHang, user.UserID, pager.idQuyen);
            }
        }
        catch (Exception ex)
        {
            return ex.Message;
        }
        return "";
    }
    public string sp_XOA_ChucDanh(long? iDChucDanh, ObjectPager pager, ObjectAspUser user)
    {
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                DTO.sp_XOA_ChucDanh(iDChucDanh, user.IDKhachHang, user.UserID, pager.idQuyen);
            }
        }
        catch (Exception ex)
        {
            return ex.Message;
        }
        return "";
    }
    public string sp_XOA_NhanSu(long? iDNhanSu, ObjectPager pager, ObjectAspUser user)
    {
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                DTO.sp_XOA_NhanSu(iDNhanSu, user.IDKhachHang, user.UserID, pager.idQuyen);
            }
        }
        catch (Exception ex)
        {
            return ex.Message;
        }
        return "";
    }
    public string sp_XOA_NhomCap(long? iDNhomCap, ObjectPager pager, ObjectAspUser user)
    {
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                DTO.sp_XOA_NhomCap(iDNhomCap, user.IDKhachHang, user.UserID, pager.idQuyen);
            }
        }
        catch (Exception ex)
        {
            return ex.Message;
        }
        return "";
    }
    public string sp_XOA_HeThongTanSuat(long? idHTTS, long? idHTMT, ObjectPager pager, ObjectAspUser user)
    {
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                DTO.sp_XOA_HeThongTanSuat(idHTTS, idHTMT, user.UserID, pager.idQuyen);
            }
        }
        catch (Exception ex)
        {
            return ex.Message;
        }
        return "";
    }
    public List<TW_HeThongTanSuatBase> sp_LAY_DSHeThongTanSuat(long? iDHTMT, bool? suDung, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        var list = new List<TW_HeThongTanSuatBase>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DSHeThongTanSuat(iDHTMT, suDung, pager.pageSize, pager.pageIndex, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang, false).ToList();
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return list;
        }
        return list;
    }
    public List<TW_NhomCapBase> LAY_DSNhomCap(bool? suDung, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        var list = new List<TW_NhomCapBase>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DSNhomCap(suDung, pager.pageSize, pager.pageIndex, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return list;
        }
        return list;
    }
    public List<DDL_CoCau> LAY_DDL_CoCau(long? idNhomCap, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_CoCau>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DDL_CoCau(idNhomCap, user.UserID, pager.idQuyen, user.IDKhachHang, false).ToList();
            }
        }
        catch
        {
            return list;
        }
        return list;
    }
    public List<DDL_CoCauVaNhanSu> LAY_DDL_CoCauCon(long? idCoCau, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_CoCauVaNhanSu>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DDL_CoCauCon(idCoCau, user.UserID, pager.idQuyen, user.IDKhachHang, false).ToList();
            }
        }
        catch(Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<DDL_TrangThaiNhanSu> LAY_DDL_TrangThaiNhanSu(ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_TrangThaiNhanSu>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DDL_TrangThaiNhanSu(user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch (Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<DDL_NhomCap> LAY_DDL_NhomCap(ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_NhomCap>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DDL_NhomCap(user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch (Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<DDL_HeThongTanSuat> sp_LAY_DDL_HeThongTanSuat(long? iDHTMT, byte? iDLoaiTanSuat, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_HeThongTanSuat>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DDL_HeThongTanSuat(iDHTMT, iDLoaiTanSuat, user.UserID, pager.idQuyen, user.IDKhachHang, false).ToList();
            }
        }
        catch
        {
            return list;
        }
        return list;
    }

    public List<DDL_NhanSu> sp_LAY_DDL_NhanSu(ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_NhanSu>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DDL_NhanSu(null, null, user.UserID, pager.idQuyen, user.IDKhachHang, false).ToList();
            }
        }
        catch
        {
            return list;
        }
        return list;
    }
    public List<DDL_NhanSuSearch> sp_LAY_DLL_NhanSuSearch_AllChucDanh(string listID, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_NhanSuSearch>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DLL_NhanSuSearch_AllChucDanh(listID, null, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch (Exception ex)
        {
            return list;
        }
        return list;
    }

    public List<ObjectID> sp_LAY_DS_IDCoCau(long? idNhomCap, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<ObjectID>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DS_IDCoCau(idNhomCap, user.UserID, pager.idQuyen, user.IDKhachHang, false).ToList();
            }
        }
        catch (Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<ObjectID> sp_LAY_DS_IDNhanSu(string listID, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<ObjectID>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                if (string.IsNullOrEmpty(listID)) listID = null;
                list = DTO.sp_LAY_DS_IDNhanSu(listID, null, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch (Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<DDL_NhanSuSearch> sp_LAY_DDL_NhanSuSearch(string listID, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_NhanSuSearch>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DLL_NhanSuSearch(listID, null, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch(Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<DDL_NhanSuSearch> sp_LAY_DLL_NhanSuSearchFull(string listID, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_NhanSuSearch>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DLL_NhanSuSearchFull(listID, null, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch (Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<DDL_NhanSuSearch> sp_LAY_DLL_NhanSuSearchAdvance(string listID, long? IDCoCau, long? IDChucDanh, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_NhanSuSearch>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DLL_NhanSuSearchAdvance(listID, IDCoCau, IDChucDanh, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch (Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<DDL_ChucDanhSearch> sp_LAY_DDL_ChucDanhSearch(long? iDChucDanh, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_ChucDanhSearch>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DLL_ChucDanhSearch(iDChucDanh, null, null, pager.keyword, user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch(Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<DLL_ChucDanhNhanSu> sp_LAY_DLL_ChucDanhNhanSu(long? iDNhanSu, ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DLL_ChucDanhNhanSu>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DLL_ChucDanhNhanSu(iDNhanSu, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch (Exception ex)
        {
            return list;
        }
        return list;
    }
    public List<DDL_NhomCap> sp_LAY_DDL_NhomCap(ObjectPager pager, ObjectAspUser user)
    {
        var list = new List<DDL_NhomCap>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DDL_NhomCap(user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
            }
        }
        catch
        {
            return list;
        }
        return list;
    }
    public string sp_LUU_KhachHang(SYS_KhachHangBase obj, ObjectPager pager, ObjectAspUser user)
    {
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                var result = DTO.sp_LUU_KhachHang(obj.IDKhachHang,obj.Code,obj.Name,obj.Email,obj.IsDisabled,obj.IsDeleted,obj.NgayDangKy,obj.NgayHieuLuc,obj.NgayHetHan, user.UserID, pager.idQuyen);
                if (result == 0) return "";
            }
        }
        catch (Exception ex)
        {
            return ex.Message;
        }
        return "";
    }
    public List<SYS_KhachHangBase> sp_LAY_DSKhachHang(bool? Isdeleted, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        var list = new List<SYS_KhachHangBase>();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                list = DTO.sp_LAY_DSKhachHang(pager.pageSize, pager.pageIndex, pager.keyword, Isdeleted, user.UserID, pager.idQuyen, user.IDKhachHang).ToList();
                if (list != null)
                {
                    for (int i = 0; i < list.Count; i++)
                    {
                        list[i].sNgayDangKy = Helper.toNgayThangNam(list[i].NgayDangKy);
                        list[i].sNgayHetHan = Helper.toNgayThangNam(list[i].NgayHetHan);
                        list[i].sNgayHieuLuc = Helper.toNgayThangNam(list[i].NgayHieuLuc);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return list;
        }
        return list;
    }
    public SYS_KhachHangBase sp_LAY_KhachHang(int? id, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        SYS_KhachHangBase objNew = new SYS_KhachHangBase();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                objNew = DTO.sp_LAY_KhachHang(id, user.UserID, pager.idQuyen, user.IDKhachHang).SingleOrDefault();
                if (objNew != null)
                {
                    objNew.sNgayDangKy = objNew.NgayDangKy == null ? "" : Helper.toNgayThangNam(objNew.NgayDangKy);
                    objNew.sNgayHetHan = objNew.NgayHetHan == null ? "" : Helper.toNgayThangNam(objNew.NgayHetHan);
                    objNew.sNgayHieuLuc = objNew.NgayHieuLuc == null ? "" : Helper.toNgayThangNam(objNew.NgayHieuLuc);
                }
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return objNew;
        }
        return objNew;
    }
    public SYS_CoCau LAY_CoCau(long? id, ObjectPager pager, ObjectAspUser user, ref int iUpdate, ref string err)
    {
        err = "";
        iUpdate = 0;
        var obj = new SYS_CoCau();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                obj = DTO.SYS_CoCaus.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDCoCau == id).FirstOrDefault();
                //Check Quyen
                switch(pager.idQuyen)
                {
                    case 1: if (obj.IDCoCau == user.IDCoCau) iUpdate = 1; break;
                    case 2: if (obj.IDCoCau == user.IDCoCau) iUpdate = 1; break;
                    case 3: if (DTO.SYS_CoCaus.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDCoCau == id).Count() > 0) iUpdate = 1; break;//CayThuMuc
                    case 4: if (DTO.SYS_CoCaus.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDCoCau == id).Count() > 0) iUpdate = 1; break;//CayThuMuc
                    case 5: iUpdate = 1; break;
                }    
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return obj;
        }

        return obj;
    }
    public SYS_ChucDanh LAY_ChucDanh(long? id, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        var obj = new SYS_ChucDanh();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                obj = DTO.SYS_ChucDanhs.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDChucDanh == id).FirstOrDefault();
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return obj;
        }

        return obj;
    }
    public SYS_NhanSuOne LAY_NhanSu(long? id, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        var obj = new SYS_NhanSuOne();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                var objNew = DTO.SYS_NhanSus.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDNhanSu == id).FirstOrDefault();
                if (objNew != null)
                {
                    obj.IDNhanSu = objNew.IDNhanSu;
                    obj.IDCoCau = objNew.IDCoCau;
                    obj.IDChucDanh = objNew.IDChucDanh;
                    obj.MaNhanSu = objNew.MaNhanSu;
                    obj.HoVaTen = objNew.HoVaTen;
                    obj.TrangThai = objNew.TrangThai;
                    obj.AnhNhanSu = objNew.AnhNhanSu;
                    obj.NgayHieuLuc = objNew.NgayHieuLuc;
                    obj.NgayHetHan = objNew.NgayHetHan;
                    obj.IsDanhGia = objNew.IsDanhGia;
                    obj.IsDelete = objNew.IsDelete;
                    obj.TenNhanSuNgan = objNew.TenNhanSuNgan;
                    obj.sNgayHieuLuc = Helper.toNgayThangNam(objNew.NgayHieuLuc);
                    obj.sNgayHetHan = Helper.toNgayThangNam(objNew.NgayHetHan);
                } 
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return obj;
        }
        return obj;
    }
    public NhanSu_Login sp_Login(string email, ref string err)
    {
        err = "";
        var obj = new NhanSu_Login();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                obj = DTO.sp_Login(email).FirstOrDefault();
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return obj;
        }
        return obj;
    }
    public TW_NhomCap LAY_NhomCap(long? id, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        var obj = new TW_NhomCap();
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                obj = DTO.TW_NhomCaps.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDNhomCap == id).FirstOrDefault();
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return obj;
        }

        return obj;
    }
    public SYS_CoCau LUU_CoCau(SYS_CoCau obj, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        long? IDChaOld = 0;
        int Count = 0;
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                if (obj.IDCoCau == null) obj.IDCoCau = 0;
                if (obj.IDCoCau == 0)//Insert
                {
                    //Check duplicate
                    Count = DTO.SYS_CoCaus.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == user.IDKhachHang && x.MaCoCau.ToLower() == obj.MaCoCau.ToLower()).Count();
                    if (Count > 0)
                    {
                        err = Helper.IsDuplicateCode(); //Trùng mã
                        DTO.Dispose(); goto Finish;
                    }
                    var objNew = new SYS_CoCau();
                    DateTime now = DateTime.Now;
                    objNew.CreatedDate = now;
                    objNew.CreatedBy = user.UserID;
                    objNew.LastUpdatedDate = now;
                    objNew.LastUpdatedBy = user.UserID;

                    objNew.IDCoCau = obj.IDCoCau;
                    objNew.MaCoCau = obj.MaCoCau;
                    objNew.MaTichHop = obj.MaTichHop;
                    objNew.TenCoCau = obj.TenCoCau;
                    objNew.TenCoCauNgan = obj.TenCoCauNgan;
                    objNew.IDNhomCap = obj.IDNhomCap;
                    objNew.SuDung = obj.SuDung;
                    objNew.MoTa = obj.MoTa;
                    objNew.IDCha = obj.IDCha == null ? 0 : obj.IDCha;
                    if (obj.IDCha == null)
                    {
                        objNew.CapBac = 1;
                    }
                    objNew.IDKhachHang = user.IDKhachHang;
                    //objNew.NgayBatDau = Helper.TodateVN(obj.sNgayBatDau);
                    DTO.SYS_CoCaus.InsertOnSubmit(objNew);
                    DTO.SubmitChanges();
                    obj.IDCoCau = objNew.IDCoCau;
                }
                else
                {//Update
                 //Check duplicate Code
                    Count = DTO.SYS_CoCaus.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == user.IDKhachHang && x.MaCoCau.ToLower() == obj.MaCoCau.ToLower() && x.IDCoCau != obj.IDCoCau).Count();
                    if (Count > 0)
                    {
                        err = Helper.IsDuplicateCode(); //Trùng mã
                        DTO.Dispose(); goto Finish;
                    }
                    var objNew = DTO.SYS_CoCaus.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDCoCau == obj.IDCoCau).SingleOrDefault();
                    if (objNew != null)
                    {
                        IDChaOld = objNew.IDCha;
                        DateTime now = DateTime.Now;
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.IDCoCau = obj.IDCoCau;
                        objNew.MaCoCau = obj.MaCoCau;
                        objNew.MaTichHop = obj.MaTichHop;
                        objNew.TenCoCau = obj.TenCoCau;
                        objNew.TenCoCauNgan = obj.TenCoCauNgan;
                        objNew.IDNhomCap = obj.IDNhomCap;
                        objNew.SuDung = obj.SuDung;
                        objNew.MoTa = obj.MoTa;
                        objNew.IDCha = obj.IDCha == null ? 0 : obj.IDCha;
                        if (obj.IDCha == null)
                        {
                            objNew.CapBac = 1;
                        }
                        objNew.IDKhachHang = user.IDKhachHang;
                        DTO.SubmitChanges();
                    }
                }
                //Sắp xêp đơn vị
                DTO.CommandTimeout = 1800;
                DTO.sp_THI_CoCau_SapXep(obj.IDCoCau, IDChaOld, obj.IDCha, user.UserID, user.IDKhachHang);
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return obj;
        }
    Finish:
        return obj;
    }
    public bool DongBo_KhachHang(SYS_KhachHang obj, ObjectAspUser user, ref string err)
    {
        err = "";
        int Count = 0;
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                //Tìm theo ID Đồng bộ
                Count = DTO.SYS_KhachHangs.Where(x => x.IDKhachHang == obj.IDKhachHang).Count();
                if (Count == 1)
                {
                    //Update
                    var objNew = DTO.SYS_KhachHangs.Where(x => x.IDKhachHang == obj.IDKhachHang).SingleOrDefault();
                    if (objNew != null)
                    {
                        objNew.LastUpdatedDate = DateTime.Now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.Code = obj.Code;
                        objNew.Name = obj.Name;
                        objNew.Email = obj.Email;
                        objNew.IsDisabled = false;
                        DTO.SubmitChanges();
                    }
                }
                else
                {
                    //Check by code
                    var objNewCode = DTO.SYS_KhachHangs.Where(x => x.Code.ToLower() == obj.Code.ToLower()).SingleOrDefault();
                    if (objNewCode != null)
                    {
                        objNewCode.LastUpdatedDate = DateTime.Now;
                        objNewCode.LastUpdatedBy = user.UserID;

                        objNewCode.Code = obj.Code;
                        objNewCode.Name = obj.Name;
                        objNewCode.Email = obj.Email;
                        objNewCode.IsDisabled = false;
                        DTO.SubmitChanges();
                        return true;
                    }

                    //Insert
                    var objNew = new SYS_KhachHang();
                    DateTime now = DateTime.Now;
                    objNew.LastUpdatedDate = now;
                    objNew.LastUpdatedBy = user.UserID;

                    objNew.IDKhachHang = obj.IDKhachHang;
                    objNew.Code = obj.Code;
                    objNew.Name = obj.Name;
                    objNew.Email = obj.Email;
                    objNew.IsDisabled = false;
                    DTO.SYS_KhachHangs.InsertOnSubmit(objNew);
                    DTO.SubmitChanges();
                }
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return false;
        }
        return true;
    }
    public bool DongBo_CoCau(SYS_CoCau obj, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        long? IDChaOld = 0;
        int Count = 0;
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                DateTime now = DateTime.Now;
                //Tìm theo ID Đồng bộ
                Count = DTO.SYS_CoCaus.Where(x => x.DB_IDCoCau == obj.DB_IDCoCau).Count();
                if(Count==1)
                {
                    //Update
                    var objNew = DTO.SYS_CoCaus.Where(x => x.DB_IDCoCau == obj.DB_IDCoCau).SingleOrDefault();
                    if (objNew != null)
                    {
                        IDChaOld = objNew.IDCha;
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.DB_IDCoCau = obj.DB_IDCoCau;
                        objNew.DB_IDCha = obj.DB_IDCha == null ? 0 : obj.DB_IDCha;

                        objNew.MaCoCau = obj.MaCoCau;
                        objNew.IDKhachHang = obj.IDKhachHang;
                        objNew.TenCoCau = obj.TenCoCau;
                        //objNew.TenCoCauNgan = obj.TenCoCauNgan;
                        objNew.SuDung = true;
                        objNew.MoTa = obj.MoTa;
                        objNew.ThuTu = obj.ThuTu;
                        objNew.IsDelete = obj.IsDelete;
                        objNew.IDCha = 0;
                        objNew.CapBac = 1;
                        DTO.SubmitChanges();
                    }
                }    
                else
                {
                    //Tìm theo mã cơ cấu
                    var objNew = DTO.SYS_CoCaus.Where(x => x.IDKhachHang == obj.IDKhachHang && x.MaCoCau.ToUpper() == obj.MaCoCau.ToUpper() && (x.IsDelete == false || x.IsDelete == null)).FirstOrDefault();
                    if (objNew != null)
                    {
                        IDChaOld = objNew.IDCha;
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.DB_IDCoCau = obj.DB_IDCoCau;
                        objNew.DB_IDCha = obj.DB_IDCha == null ? 0 : obj.DB_IDCha;

                        objNew.MaCoCau = obj.MaCoCau;
                        objNew.IDKhachHang = obj.IDKhachHang;
                        objNew.TenCoCau = obj.TenCoCau;
                        //objNew.TenCoCauNgan = obj.TenCoCauNgan;
                        objNew.SuDung = true;
                        objNew.MoTa = obj.MoTa;
                        objNew.ThuTu = obj.ThuTu;
                        objNew.IsDelete = obj.IsDelete;
                        objNew.IDCha = 0;
                        objNew.CapBac = 1;
                        DTO.SubmitChanges();
                    }
                    else
                    {
                        //Insert
                        objNew = new SYS_CoCau();
                        objNew.CreatedDate = now;
                        objNew.CreatedBy = user.UserID;
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.DB_IDCoCau = obj.DB_IDCoCau;
                        objNew.DB_IDCha = obj.DB_IDCha == null ? 0 : obj.DB_IDCha;

                        objNew.MaCoCau = obj.MaCoCau;
                        objNew.IDKhachHang = obj.IDKhachHang;
                        objNew.TenCoCau = obj.TenCoCau;
                        //objNew.TenCoCauNgan = obj.TenCoCauNgan;
                        objNew.SuDung = true;
                        objNew.MoTa = obj.MoTa;
                        objNew.ThuTu = obj.ThuTu;
                        objNew.IsDelete = obj.IsDelete;
                        objNew.IDCha = 0;
                        objNew.CapBac = 1;
                        DTO.SYS_CoCaus.InsertOnSubmit(objNew);
                        DTO.SubmitChanges();
                    }
                }    
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return false;
        }
        return true;
    }
    public bool DongBo_CoCauUpdateIDCha(int IDKhachHang, ref string err)
    {
        err = "";
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                var list = DTO.SYS_CoCaus.Where(x => x.DB_IDCha > 0 && x.IDKhachHang == IDKhachHang).ToList();
                for (int i = 0; i < list.Count(); i++)
                {
                    string DB_IDCoCau = list[i].DB_IDCoCau.ToString();
                    string DB_IDCha = list[i].DB_IDCha.ToString();
                    try
                    {
                        var objCha = DTO.SYS_CoCaus.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.DB_IDCoCau == list[i].DB_IDCha).SingleOrDefault();
                        if (objCha != null)
                        {
                            list[i].IDCha = objCha.IDCoCau;
                        }
                    }
                    catch (Exception tmpErr)
                    {
                        err = tmpErr.Message;
                    }
                      
                }
                DTO.SubmitChanges();
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return false;
        }
        return true;
    }
    public bool DongBo_CoCauSapXep(ObjectAspUser user, ref string err)
    {
        err = "";
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                var list = DTO.SYS_CoCaus.Where(x => x.IDCha == 0 && x.IDKhachHang == user.IDKhachHang).ToList();
                for (int i = 0; i < list.Count(); i++)
                {
                    var obj = list[i];
                    DTO.CommandTimeout = 1800;
                    DTO.sp_THI_CoCau_SapXep(obj.IDCoCau, -1, obj.IDCha, user.UserID, user.IDKhachHang);
                }
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return false;
        }
        return true;
    }
    public SYS_ChucDanh LUU_ChucDanh(SYS_ChucDanh obj, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        
        long? IDChaOld = null;
        int Count = 0;
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                if (obj.IDChucDanh == null) obj.IDChucDanh = 0;
                if (obj.IDChucDanh == 0)//Insert
                {
                    //Check duplicate
                    Count = DTO.SYS_ChucDanhs.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == user.IDKhachHang && x.MaChucDanh.ToLower() == obj.MaChucDanh.ToLower()).Count();
                    if (Count > 0)
                    {
                        err = Helper.IsDuplicateCode(); //Trùng mã
                        DTO.Dispose(); goto Finish;
                    }
                    var objNew = new SYS_ChucDanh();
                    DateTime now = DateTime.Now;
                    objNew.CreatedDate = now;
                    objNew.CreatedBy = user.UserID;
                    objNew.LastUpdatedDate = now;
                    objNew.LastUpdatedBy = user.UserID;

                    objNew.IDChucDanh = obj.IDChucDanh;
                    objNew.IDCoCau = obj.IDCoCau;
                    objNew.MaChucDanh = obj.MaChucDanh;
                    objNew.TenChucDanh = obj.TenChucDanh;
                    objNew.TenChucDanhNgan = obj.TenChucDanhNgan;
                    objNew.LaCapTruong = obj.LaCapTruong;
                    objNew.SuDung = obj.SuDung;
                    objNew.IDKhachHang = user.IDKhachHang;
                    objNew.IDCha = obj.IDCha == null ? 0 : obj.IDCha;
                    if (obj.IDCha == null)
                    {
                        objNew.CapBac = 1;
                    }
                    //objNew.NgayBatDau = Helper.TodateVN(obj.sNgayBatDau);
                    DTO.SYS_ChucDanhs.InsertOnSubmit(objNew);
                    DTO.SubmitChanges();
                }
                else
                {//Update
                 //Check duplicate Code
                    Count = DTO.SYS_ChucDanhs.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == user.IDKhachHang && x.MaChucDanh.ToLower() == obj.MaChucDanh.ToLower() && x.IDChucDanh != obj.IDChucDanh).Count();
                    if (Count > 0)
                    {
                        err = Helper.IsDuplicateCode(); //Trùng mã
                        DTO.Dispose(); goto Finish;
                    }
                    var objNew = DTO.SYS_ChucDanhs.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDChucDanh == obj.IDChucDanh).SingleOrDefault();
                    if (objNew != null)
                    {
                        DateTime now = DateTime.Now;
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.IDChucDanh = obj.IDChucDanh;
                        objNew.IDCoCau = obj.IDCoCau;
                        objNew.MaChucDanh = obj.MaChucDanh;
                        objNew.TenChucDanh = obj.TenChucDanh;
                        objNew.TenChucDanhNgan = obj.TenChucDanhNgan;
                        objNew.LaCapTruong = obj.LaCapTruong;
                        objNew.SuDung = obj.SuDung;
                        objNew.IDKhachHang = user.IDKhachHang;
                        objNew.IDCha = obj.IDCha == null ? 0 : obj.IDCha;
                        if (obj.IDCha == null)
                        {
                            objNew.CapBac = 1;
                        }
                        DTO.SubmitChanges();
                    }
                }
                //Sắp xếp chức danh
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return obj;
        }
    Finish:
        return obj;
    }
    public long? getIDCoCau(long? IDCoCau, int IDKhachHang)
    {
        using (var DTO = new DTODataContext(_connection))
        {
            DTO.CommandTimeout = 0;
            var obj = DTO.SYS_CoCaus.Where(x => x.IDKhachHang == IDKhachHang && x.IDCoCau == IDCoCau).SingleOrDefault();
            if (obj != null)
            {
                return obj.IDCoCau;
            }
        }
        return null;
    }
    public long? getIDCoCauDongBo(long? DB_IDCoCau, int IDKhachHang)
    {
        using (var DTO = new DTODataContext(_connection))
        {
            DTO.CommandTimeout = 0;
            var obj = DTO.SYS_CoCaus.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == IDKhachHang && x.DB_IDCoCau == DB_IDCoCau).SingleOrDefault();
            if(obj!=null)
            {
                return obj.IDCoCau;
            }    
        }
        return null;
    }
    public long? getIDChucDanhDongBo(long? DB_IDChucDanh, int IDKhachHang)
    {
        using (var DTO = new DTODataContext(_connection))
        {
            DTO.CommandTimeout = 0;
            var obj = DTO.SYS_ChucDanhs.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == IDKhachHang && x.DB_IDChucDanh == DB_IDChucDanh).SingleOrDefault();
            if (obj != null)
            {
                return obj.IDChucDanh;
            }
        }
        return null;
    }
    public bool DongBo_ChucDanh(SYS_ChucDanh obj, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        int Count = 0;
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                DateTime now = DateTime.Now;
                //Tìm theo ID Đồng bộ
                Count = DTO.SYS_ChucDanhs.Where(x => x.DB_IDChucDanh == obj.DB_IDChucDanh).Count();
                if (Count == 1)
                {
                    //Update
                    var objNew = DTO.SYS_ChucDanhs.Where(x => x.DB_IDChucDanh == obj.DB_IDChucDanh).SingleOrDefault();
                    if (objNew != null)
                    {
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.DB_IDChucDanh = obj.DB_IDChucDanh;
                        objNew.DB_IDCha = obj.DB_IDCha == null ? 0 : obj.DB_IDCha;

                        objNew.MaChucDanh = obj.MaChucDanh;
                        objNew.IDKhachHang = obj.IDKhachHang;
                        objNew.TenChucDanh = obj.TenChucDanh;
                        //objNew.TenChucDanhNgan = obj.TenChucDanhNgan;
                        objNew.LaCapTruong = obj.LaCapTruong;
                        objNew.SuDung = true;
                        objNew.IDCoCau = getIDCoCauDongBo(obj.IDCoCau, user.IDKhachHang);
                        objNew.IsDelete = obj.IsDelete;
                        objNew.IDCha = 0;
                        DTO.SubmitChanges();
                    }
                }
                else
                {
                    //Tìm theo mã chức danh
                    var objNew = DTO.SYS_ChucDanhs.Where(x => x.IDKhachHang == obj.IDKhachHang && x.MaChucDanh.ToUpper() == obj.MaChucDanh.ToUpper() && (x.IsDelete == false || x.IsDelete == null)).FirstOrDefault();
                    if (objNew != null)
                    {
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.DB_IDChucDanh = obj.DB_IDChucDanh;
                        objNew.DB_IDCha = obj.DB_IDCha == null ? 0 : obj.DB_IDCha;

                        objNew.MaChucDanh = obj.MaChucDanh;
                        objNew.IDKhachHang = obj.IDKhachHang;
                        objNew.TenChucDanh = obj.TenChucDanh;
                        //objNew.TenChucDanhNgan = obj.TenChucDanhNgan;
                        objNew.LaCapTruong = obj.LaCapTruong;
                        objNew.SuDung = true;
                        objNew.IDCoCau = getIDCoCauDongBo(obj.IDCoCau, user.IDKhachHang);
                        objNew.IsDelete = obj.IsDelete;
                        objNew.IDCha = 0;
                        DTO.SubmitChanges();
                    }
                    else
                    {
                        //Insert
                        objNew = new SYS_ChucDanh();
                        objNew.CreatedDate = now;
                        objNew.CreatedBy = user.UserID;
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.DB_IDChucDanh = obj.DB_IDChucDanh;
                        objNew.DB_IDCha = obj.DB_IDCha == null ? 0 : obj.DB_IDCha;

                        objNew.MaChucDanh = obj.MaChucDanh;
                        objNew.IDKhachHang = obj.IDKhachHang;
                        objNew.TenChucDanh = obj.TenChucDanh;
                        //objNew.TenChucDanhNgan = obj.TenChucDanhNgan;
                        objNew.LaCapTruong = obj.LaCapTruong;
                        objNew.SuDung = true;
                        objNew.IDCoCau = getIDCoCauDongBo(obj.IDCoCau, user.IDKhachHang);
                        objNew.IsDelete = obj.IsDelete;
                        objNew.IDCha = 0;
                        objNew.CapBac = 1;
                        DTO.SYS_ChucDanhs.InsertOnSubmit(objNew);
                        DTO.SubmitChanges();
                    }
                }
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return false;
        }
        return true;
    }
    public bool DongBo_ChucDanhUpdateIDCha(int IDKhachHang, ref string err)
    {
        err = "";
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                var list = DTO.SYS_ChucDanhs.Where(x => x.DB_IDCha > 0 && IDKhachHang == IDKhachHang).ToList();
                for (int i = 0; i < list.Count(); i++)
                {
                    var objCha = DTO.SYS_ChucDanhs.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.DB_IDChucDanh == list[i].DB_IDCha).SingleOrDefault();
                    if (objCha != null)
                    {
                        list[i].IDCha = objCha.IDChucDanh;
                    }
                }
                DTO.SubmitChanges();
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return false;
        }
        return true;
    }
    public bool DongBo_ChucDanhSapXep(ObjectAspUser user, ref string err)
    {
        err = "";
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                var list = DTO.SYS_ChucDanhs.Where(x => x.IDCha == 0 && x.IDKhachHang == user.IDKhachHang).ToList();
                for (int i = 0; i < list.Count(); i++)
                {
                    var obj = list[i];
                    DTO.CommandTimeout = 1800;
                    DTO.sp_THI_ChucDanh_SapXep(obj.IDChucDanh, -1, obj.IDCha, user.UserID, user.IDKhachHang);
                }
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return false;
        }
        return true;
    }
    public bool DongBo_NhanSu(SYS_NhanSu obj, ObjectAspUser user, ref string err)
    {
        err = "";
        long? IDChaOld = 0;
        int Count = 0;
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                DateTime now = DateTime.Now;
                //Tìm theo ID Đồng bộ
                Count = DTO.SYS_NhanSus.Where(x => x.DB_IDNhanSu == obj.DB_IDNhanSu).Count();
                if (Count == 1)
                {
                    //Update
                    var objNew = DTO.SYS_NhanSus.Where(x => x.DB_IDNhanSu == obj.DB_IDNhanSu).SingleOrDefault();
                    if (objNew != null)
                    {
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.DB_IDNhanSu = obj.DB_IDNhanSu;
                        objNew.DB_UserName = obj.DB_UserName;

                        objNew.IDCoCau = getIDCoCauDongBo(obj.IDCoCau, user.IDKhachHang);
                        objNew.IDChucDanh = getIDChucDanhDongBo(obj.IDChucDanh, user.IDKhachHang);
                        objNew.MaNhanSu = obj.MaNhanSu;
                        objNew.IDKhachHang = obj.IDKhachHang;
                        objNew.HoVaTen = obj.HoVaTen;
                        objNew.Email = obj.Email;
                        //objNew.TenNhanSuNgan = obj.TenNhanSuNgan;
                        objNew.AnhNhanSu = obj.AnhNhanSu;
                        objNew.NgayHieuLuc = obj.NgayHieuLuc;
                        objNew.NgayHetHan = obj.NgayHetHan;
                        //objNew.IsDanhGia = obj.IsDanhGia;
                        objNew.IsDelete = obj.IsDelete;
                        objNew.TrangThai = obj.TrangThai;
                        DTO.SubmitChanges();
                    }
                }
                else
                {
                    //Tìm theo mã nhân viên
                    var objNew = DTO.SYS_NhanSus.Where(x => x.IDKhachHang == obj.IDKhachHang && x.MaNhanSu.ToUpper() == obj.MaNhanSu.ToUpper() && (x.IsDelete == false || x.IsDelete == null)).FirstOrDefault();
                    if (objNew != null)
                    {
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.DB_IDNhanSu = obj.DB_IDNhanSu;
                        objNew.DB_UserName = obj.DB_UserName;

                        objNew.IDCoCau = getIDCoCauDongBo(obj.IDCoCau, user.IDKhachHang);
                        objNew.IDChucDanh = getIDChucDanhDongBo(obj.IDChucDanh, user.IDKhachHang);
                        objNew.MaNhanSu = obj.MaNhanSu;
                        objNew.IDKhachHang = obj.IDKhachHang;
                        objNew.HoVaTen = obj.HoVaTen;
                        objNew.Email = obj.Email;
                        //objNew.TenNhanSuNgan = obj.TenNhanSuNgan;
                        objNew.AnhNhanSu = obj.AnhNhanSu;
                        objNew.NgayHieuLuc = obj.NgayHieuLuc;
                        objNew.NgayHetHan = obj.NgayHetHan;
                        //objNew.IsDanhGia = obj.IsDanhGia;
                        objNew.IsDelete = obj.IsDelete;
                        objNew.TrangThai = obj.TrangThai;
                        DTO.SubmitChanges();
                    }
                    else
                    {
                        //Insert
                        objNew = new SYS_NhanSu();
                        objNew.CreatedDate = now;
                        objNew.CreatedBy = user.UserID;
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.DB_IDNhanSu = obj.DB_IDNhanSu;
                        objNew.DB_UserName = obj.DB_UserName;

                        objNew.IDCoCau = getIDCoCauDongBo(obj.IDCoCau, user.IDKhachHang);
                        objNew.IDChucDanh = getIDChucDanhDongBo(obj.IDChucDanh, user.IDKhachHang);
                        objNew.MaNhanSu = obj.MaNhanSu;
                        objNew.IDKhachHang = obj.IDKhachHang;
                        objNew.HoVaTen = obj.HoVaTen;
                        objNew.Email = obj.Email;
                        //objNew.TenNhanSuNgan = obj.TenNhanSuNgan;
                        objNew.AnhNhanSu = obj.AnhNhanSu;
                        objNew.NgayHieuLuc = obj.NgayHieuLuc;
                        objNew.NgayHetHan = obj.NgayHetHan;
                        objNew.IsDanhGia = true;
                        objNew.IsDelete = obj.IsDelete;
                        objNew.TrangThai = obj.TrangThai;
                        DTO.SYS_NhanSus.InsertOnSubmit(objNew);
                        DTO.SubmitChanges();
                    }
                }
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return false;
        }
        return true;
    }
    public SYS_NhanSu LUU_NhanSu(SYS_NhanSu obj, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        int Count = 0;
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                if (obj.IDNhanSu == 0)//Insert
                {
                    //Check duplicate
                    Count = DTO.SYS_NhanSus.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == user.IDKhachHang && x.MaNhanSu.ToLower() == obj.MaNhanSu.ToLower()).Count();
                    if (Count > 0)
                    {
                        err = Helper.IsDuplicateCode(); //Trùng mã
                        DTO.Dispose(); goto Finish;
                    }
                    var objNew = new SYS_NhanSu();
                    DateTime now = DateTime.Now;
                    objNew.CreatedDate = now;
                    objNew.CreatedBy = user.UserID;
                    objNew.LastUpdatedDate = now;
                    objNew.LastUpdatedBy = user.UserID;

                    objNew.IDCoCau = obj.IDCoCau;
                    objNew.IDChucDanh = obj.IDChucDanh;
                    objNew.MaNhanSu = obj.MaNhanSu;
                    objNew.HoVaTen = obj.HoVaTen;
                    objNew.TenNhanSuNgan = obj.TenNhanSuNgan;
                    objNew.TrangThai = obj.TrangThai;
                    objNew.MatKhau = obj.MatKhau;
                    objNew.NgayHieuLuc = obj.NgayHieuLuc;
                    objNew.NgayHetHan = obj.NgayHetHan;
                    objNew.IsDanhGia = obj.IsDanhGia;
                    objNew.AnhNhanSu = obj.MaNhanSu + ".jpg";
                    //objNew.AnhNhanSu = obj.AnhNhanSu;
                    objNew.IDKhachHang = user.IDKhachHang;

                    //objNew.NgayBatDau = Helper.TodateVN(obj.sNgayBatDau);
                    DTO.SYS_NhanSus.InsertOnSubmit(objNew);
                    DTO.SubmitChanges();
                }
                else
                {//Update
                 //Check duplicate Code
                    Count = DTO.SYS_NhanSus.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == user.IDKhachHang && x.MaNhanSu.ToLower() == obj.MaNhanSu.ToLower() && x.IDNhanSu != obj.IDNhanSu).Count();
                    if (Count > 0)
                    {
                        err = Helper.IsDuplicateCode(); //Trùng mã
                        DTO.Dispose(); goto Finish;
                    }
                    var objNew = DTO.SYS_NhanSus.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDNhanSu == obj.IDNhanSu).SingleOrDefault();
                    if (objNew != null)
                    {
                        DateTime now = DateTime.Now;
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.IDCoCau = obj.IDCoCau;
                        objNew.IDChucDanh = obj.IDChucDanh;
                        objNew.MaNhanSu = obj.MaNhanSu;
                        objNew.HoVaTen = obj.HoVaTen;
                        objNew.TenNhanSuNgan = obj.TenNhanSuNgan;
                        objNew.TrangThai = obj.TrangThai;
                        objNew.MatKhau = obj.MatKhau;
                        objNew.AnhNhanSu = obj.MaNhanSu + ".jpg";
                        objNew.IDKhachHang = user.IDKhachHang;
                        objNew.NgayHieuLuc = obj.NgayHieuLuc;
                        objNew.NgayHetHan = obj.NgayHetHan;
                        objNew.IsDanhGia = obj.IsDanhGia;
                        DTO.SubmitChanges();
                    }
                }
                //Sắp xếp chức danh
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return obj;
        }
    Finish:
        return obj;
    }
    public TW_NhomCap LUU_NhomCap(TW_NhomCap obj, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        err = "";
        int Count = 0;
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                if (obj.IDNhomCap == 0)//Insert
                {
                    //Check duplicate
                    Count = DTO.TW_NhomCaps.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == user.IDKhachHang && x.MaNhomCap.ToLower() == obj.MaNhomCap.ToLower()).Count();
                    if (Count > 0)
                    {
                        err = Helper.IsDuplicateCode(); //Trùng mã
                        DTO.Dispose(); goto Finish;
                    }
                    var objNew = new TW_NhomCap();
                    DateTime now = DateTime.Now;
                    objNew.CreatedDate = now;
                    objNew.CreatedBy = user.UserID;
                    objNew.LastUpdatedDate = now;
                    objNew.LastUpdatedBy = user.UserID;

                    objNew.IDNhomCap = obj.IDNhomCap;
                    objNew.MaNhomCap = obj.MaNhomCap;
                    objNew.TenNhomCap = obj.TenNhomCap;
                    objNew.SuDung = obj.SuDung;
                    objNew.ThuTu = obj.ThuTu;
                    objNew.IDKhachHang = user.IDKhachHang;

                    //objNew.NgayBatDau = Helper.TodateVN(obj.sNgayBatDau);
                    DTO.TW_NhomCaps.InsertOnSubmit(objNew);
                    DTO.SubmitChanges();
                }
                else
                {//Update
                 //Check duplicate Code
                    Count = DTO.TW_NhomCaps.Where(x => (x.IsDelete == null || x.IsDelete == false) && x.IDKhachHang == user.IDKhachHang && x.MaNhomCap.ToLower() == obj.MaNhomCap.ToLower() && x.IDNhomCap != obj.IDNhomCap).Count();
                    if (Count > 0)
                    {
                        err = Helper.IsDuplicateCode(); //Trùng mã
                        DTO.Dispose(); goto Finish;
                    }
                    var objNew = DTO.TW_NhomCaps.Where(x => x.IDKhachHang == user.IDKhachHang && x.IDNhomCap == obj.IDNhomCap).SingleOrDefault();
                    if (objNew != null)
                    {
                        DateTime now = DateTime.Now;
                        objNew.LastUpdatedDate = now;
                        objNew.LastUpdatedBy = user.UserID;

                        objNew.IDNhomCap = obj.IDNhomCap;
                        objNew.MaNhomCap = obj.MaNhomCap;
                        objNew.TenNhomCap = obj.TenNhomCap;
                        objNew.SuDung = obj.SuDung;
                        objNew.ThuTu = obj.ThuTu;
                        objNew.IDKhachHang = user.IDKhachHang;
                        DTO.SubmitChanges();
                    }
                }
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return obj;
        }
    Finish:
        return obj;
    }
    public int LUU_DoiMatKhau(ObjectAspUser obj, ref string err)
    {
        err = "";
        try
        {
            using (var DTO = new DTODataContext(_connection))
            {
                //DTO.CommandTimeout = 0;
                //var objNew = DTO.AspNetUsers.Where(x => x.ID == obj.UserID && x.IDKhachHang == obj.IDKhachHang && x.Email.ToLower()==obj.UserEmail.ToLower()).SingleOrDefault();
                //if (objNew == null) return -2;
                //if (Helper.StringDecrypt(objNew.PasswordHash) != obj.PassHienTai) return -1;
                ////Change pass
                //objNew.PasswordHash = Helper.StringEncrypt(obj.PassMoi);
                //DTO.SubmitChanges();
                return 0;
            }
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return -3;
        }
    }
    public string LUU_PhanQuyen(List<ApiObjectPhanQuyen> list, long IDNhanSu)
    {
        string err = "";
        try
        {
            //code where?????
        }
        catch (Exception ex)
        {
            err = ex.Message;
            return err;
        }
        return err;
    }
    public string GetConnectionString()
    {
        var config = GetConfiguration();
        return config.GetConnectionString("DbTeamW");
    }
    public int GetPageSize()
    {
        try
        {
            var config = GetConfiguration();
            return Convert.ToInt32(config["CauHinh:PageSize"]);
        }
        catch (Exception ex)
        {
            return 20;
        }
    }
    public int GetExportExcelDanhGia()
    {
        try
        {
            var config = GetConfiguration();
            return Convert.ToInt32(config["CauHinh:ExportExcelDanhGia"]);
        }
        catch (Exception ex)
        {
            return 0;
        }
    }
    public int GetPageSizePageSizeChiTieuCha()
    {
        try
        {
            var config = GetConfiguration();
            return Convert.ToInt32(config["CauHinh:PageSizeChiTieuCha"]);
        }
        catch (Exception ex)
        {
            return 20;
        }
    }
    public int GetPageSizePageSizeChiTieuCon()
    {
        try
        {
            var config = GetConfiguration();
            return Convert.ToInt32(config["CauHinh:PageSizeChiTieuCon"]);
        }
        catch (Exception ex)
        {
            return 20;
        }
    }

    public string GetLoginURL()
    {
        try
        {
            var config = GetConfiguration();
            return config["CauHinh:loginURL"].ToString();
        }
        catch (Exception ex)
        {
            return "login";
        }
    }
}
