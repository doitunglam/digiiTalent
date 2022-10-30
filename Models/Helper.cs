using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Data.Linq;
using System.IO;
using System.Threading;
using System.Text.RegularExpressions;
using digiiTalentDTO;
using Zirpl.CalcEngine;
using OfficeOpenXml;
using OfficeOpenXml.Style;

using RestSharp;

public static class Helper
{
    public static int MaxTyLeHoanThanh = 9999;

    public static string toNamThangNgay(DateTime? d)
    {
        if (d == null) return "";
        return Convert.ToDateTime(d).ToString("yyyy-MM-dd");
    }
    public static string toNgayThangNam(DateTime? d)
    {
        if (d == null) return "";
        return Convert.ToDateTime(d).ToString("dd/MM/yyyy").Replace('-', '/');
    }
    public static string toNgayThangNamGioPhuGiay(DateTime? d)
    {
        if (d == null) return "";
        return Convert.ToDateTime(d).ToString("dd-MM-yyyy HH:mm:ss");
    }
    public static string toNamThangNgayGioPhuGiay(DateTime? d)
    {
        if (d == null) return "";
        return Convert.ToDateTime(d).ToString("yyyy-MM-dd HH:mm:ss");
    }
    public static string toThangNam(DateTime? d)
    {
        if (d == null) return "";
        return Convert.ToDateTime(d).ToString("MM/yyyy").Replace('-', '/');
    }
    public static string toNgayThangNamDefault(DateTime? d)
    {
        if (d == null) return DateTime.Now.ToString("dd/MM/yyyy").Replace('-', '/');
        return Convert.ToDateTime(d).ToString("dd/MM/yyyy").Replace('-', '/');
    }
    public static DateTime? TodateVN(string val)
    {
        try
        {
            if (string.IsNullOrEmpty(val)) return null;
            var date = Convert.ToDateTime(val);
            return date;
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static DateTime? ToDateExcel(string val)
    {
        try
        {
            if (string.IsNullOrEmpty(val)) return null;
            if(val.All(Char.IsDigit))
            {
                return DateTime.FromOADate(Convert.ToDouble(val));
            }    
            else
            { 
                return Convert.ToDateTime(val);
            }    
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static double? DateToExcelNumber(DateTime? date)
    {
        try
        {
            if (date == null) return null;
            return Convert.ToDateTime(date).ToOADate();


        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static DateTime? getFirstdate(string val)
    {
        try
        {
            if (string.IsNullOrEmpty(val)) return null;
            var date = Convert.ToDateTime(val);
            var firstdate = new DateTime(date.Year, date.Month, 1);
            return firstdate;
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static DateTime? getLastdate(string val)
    {
        try
        {
            if (string.IsNullOrEmpty(val)) return null;
            var date = Convert.ToDateTime(val);
            var lastdate = new DateTime(date.Year, date.Month, 1).AddMonths(1).AddDays(-1);
            return lastdate;
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static string NullToEmpty(object val)
    {
        if (val == null) return "";
        return val.ToString();
    }
    public static long NullToZero64(object val)
    {
        if (val == null) return 0;
        return Convert.ToInt64(val);
    }
    public static int NullToZero(object val)
    {
        if (val == null) return 0;
        return Convert.ToInt32(val);
    }
    public static decimal NullToZeroDecimal(object val)
    {
        if (val == null) return 0;
        return Convert.ToDecimal(val);
    }
    public static bool NullToFalse(bool? val)
    {
        if (val == null) return false;
        return Convert.ToBoolean(val);
    }
    public static int? ToInt32(object val)
    {
        if (val == null) return null;
        if (string.IsNullOrEmpty(val.ToString())) return null;
        try
        {
            return Convert.ToInt32(val);
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static int? DecimalToInt32(object val)
    {
        if (val == null) return null;
        if (string.IsNullOrEmpty(val.ToString())) return null;
        try
        {
            var max = Math.Ceiling(Convert.ToDecimal(val));
            return Convert.ToInt32(max);
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static long? ToInt64(object val)
    {
        if (val == null) return null;
        if (string.IsNullOrEmpty(val.ToString())) return null;
        try
        {
            return Convert.ToInt64(val);
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static byte? ToByte(object val)
    {
        if (val == null) return null;
        if (string.IsNullOrEmpty(val.ToString())) return null;
        try
        {
            return Convert.ToByte(val);
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static bool? ToBoolean(object val)
    {
        if (val == null) return null;
        if (string.IsNullOrEmpty(val.ToString())) return null;
        if (val.ToString() == "0") return false;
        if (val.ToString() == "1") return true;
        try
        {
            return Convert.ToBoolean(val);
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static bool isTrue(object val)
    {
        if (val == null) return false;
        if (string.IsNullOrEmpty(val.ToString())) return false;
        if (val.ToString() == "0") return false;
        if (val.ToString() == "1") return true;
        try
        {
            return Convert.ToBoolean(val);
        }
        catch (Exception ex)
        {
            return false;
        }
    }
    public static decimal? ToDecimal(object val)
    {
        if (val == null) return null;
        if (string.IsNullOrEmpty(val.ToString())) return null;
        try
        {
            return Convert.ToDecimal(val);
        }
        catch (Exception ex)
        {
            return null;
        }
    }
    public static string ToString(object val)
    {
        if (val == null) return "";
        return val.ToString();
    }
    public static int GetQuyen(string ListQuyen, int idQuyen)
    {
        if (ListQuyen == null) return -1;
        var arr = ListQuyen.Split('|');
        int iMax = arr.Count();
        var keyword = idQuyen.ToString() + "=";
        try
        {
            for (int i = 0; i < iMax; i++)
            {
                if (arr[i].StartsWith(keyword))
                {
                    string IDQuyen = arr[i].Substring(keyword.Length);
                    return Convert.ToInt32(IDQuyen);
                }
            }
        }
        catch
        {
            return -1;
        }
        return -1;
    }

    public static int getMaxValue(decimal? val)
    {
        int iMin = 100;
        int iStep = 10;
        for (int i = 0; i < 100; i++)
        {
            if (val < iMin) return iMin;
            else iMin += iStep;
        }
        return iMin;
    }
    
    #region Excel
    public static string getVal(object val)
    {
        if (val == null) return null;
        if (string.IsNullOrEmpty(val.ToString())) return null;
        else return val.ToString();
    }
    public static string WriteLog(long UserID, string Name, string log)
    {
        string LogName = "";
        try
        {
            string pathUser = "tmp/" + UserID;
            if (!Directory.Exists(pathUser)) Directory.CreateDirectory(pathUser);
            LogName = "ErrorLog_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".txt";
            string path = pathUser + "/" + LogName;
            using (StreamWriter sw = new StreamWriter(path))
            {
                sw.WriteLine("----------------------------------------");
                sw.WriteLine("Import tệp: " + Name);
                sw.WriteLine("Ngày giờ: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
                sw.WriteLine("----------------------------------------");
                sw.WriteLine("Thông báo lỗi:");
                sw.WriteLine("");
                sw.WriteLine(log);
            }
            return LogName;
        }
        catch (Exception ex)
        {

        }
        return LogName;
    }
    public static string Trim(object val)
    {
        if (val == null) return "";
        try
        {
            return val.ToString().Trim();
        }
        catch 
        {
            return "";
        }
    }
    public static bool IsNull(object val)
    {
        if (val == null) return true;
        if (string.IsNullOrEmpty(val.ToString())) return true;
        return false;
    }
    #endregion

    #region Import
    public static string Import_CoCau(string path, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        string step = "";
        List<ObjectMucTieuSapXep> ListSapXep = new List<ObjectMucTieuSapXep>();
        ObjectMucTieuSapXep objSapXep = new ObjectMucTieuSapXep();
        string FileName = "Import: ";
        try
        {
            int iFromRow = 8;
            step = "uploads";
            if (!Directory.Exists("uploads")) Directory.CreateDirectory("uploads");

            step = "ExcelCommercial";
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            step = "ExcelPackage";

            DTOBase b = new DTOBase();
            var _connection = b._connection;

            string Log = "";
            int iRowCT = 1;
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                string MaMucTieuError = "";
                var xlFile = new FileInfo(path);
                using (var package = new ExcelPackage(xlFile))
                {
                    step = "ExcelWorkbook";
                    FileName = xlFile.Name;
                    //Add a new worksheet to the empty workbook
                    step = "ExcelWorksheet";
                    var worksheet = package.Workbook.Worksheets[0];

                    int colCount = worksheet.Dimension.End.Column;  //get Column Count
                    int rowCount = worksheet.Dimension.End.Row;     //get row count

                    //TW_MucTieuBase obj = new TW_MucTieuBase();

                    string tmpOld = "";
                    string tmpNew = "";

                    ObjectDDL objHTMT = new ObjectDDL();
                    objHTMT.id = 0;
                    objHTMT.text = "";

                    long? IDHTMTOld = null;
                    long IDMucTieuOld = 0;
                    string CTSoThucTeOld = "";

                    for (int iRow = iFromRow; iRow <= rowCount; iRow++)
                    {
                        bool bError = false;
                        //obj = new TW_MucTieuBase();

                        //int iCol = 2;
                        //var cell = worksheet.Cells[iRow, iCol];
                        //object val = cell.Value; iCol++;//[MaHTCT]
                        //if (!IsNull(val))
                        //{
                        //    if (val.ToString() != objHTMT.text)
                        //    {
                        //        var tmp = DTO.TW_HeThongMucTieus.Where(x => x.IDKhachHang == user.IDKhachHang && (x.IsDelete == false || x.IsDelete == null) && x.MaHTMT.ToLower() == val.ToString().ToLower().Trim()).FirstOrDefault();
                        //        if (tmp != null)
                        //        {
                        //            obj.IDHTMT = tmp.IDHTMT;
                        //            objHTMT.id = tmp.IDHTMT;
                        //            objHTMT.text = tmp.MaHTMT;
                        //            if (IDHTMTOld != obj.IDHTMT)
                        //                IDHTMTOld = obj.IDHTMT;
                        //        }
                        //        else
                        //        {
                        //            bError = true;
                        //            Log += cell.Address + " - " + ErrorNotExit(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //        }
                        //    }
                        //    else obj.IDHTMT = objHTMT.id;
                        //}
                        //else
                        //{
                        //    if (IDHTMTOld != null) obj.IDHTMT = IDHTMTOld;
                        //    else
                        //    {
                        //        bError = true;
                        //        Log += cell.Address + " - " + ErrorNull(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //        continue;
                        //    }
                        //}

                        //cell = worksheet.Cells[iRow, iCol]; val = cell.Value; iCol++;//[MaChiTieu]
                        //if (!IsNull(val))
                        //{
                        //    var tmp = DTO.TW_MucTieus.Where(x => x.IDHTMT == obj.IDHTMT && (x.IsDelete == false || x.IsDelete == null) && x.MaMucTieu.ToLower() == val.ToString().ToLower().Trim()).FirstOrDefault();
                        //    if (tmp != null)
                        //    {
                        //        obj.IDMucTieu = tmp.IDMucTieu;
                        //        if (IDMucTieuOld != obj.IDMucTieu)
                        //            IDMucTieuOld = obj.IDMucTieu;
                        //    }
                        //    else
                        //    {
                        //        bError = true;
                        //        Log += cell.Address + " - " + ErrorNotExit(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //    }

                        //}
                        //else
                        //{
                        //    if (IDMucTieuOld != 0) obj.IDMucTieu = IDMucTieuOld;
                        //    else
                        //    {
                        //        bError = true;
                        //        Log += cell.Address + " - " + ErrorNull(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //        continue;
                        //    }
                        //}

                        //cell = worksheet.Cells[iRow, iCol]; val = cell.Value; iCol++;//[TenChiTieu]

                        //cell = worksheet.Cells[iRow, iCol]; val = cell.Value; iCol++;//[CongThucTinhSoThucTe]
                        //if (!IsNull(val))
                        //{
                        //    obj.CTSoThucTe = getVal(val);
                        //    if (CTSoThucTeOld != obj.CTSoThucTe)
                        //        CTSoThucTeOld = obj.CTSoThucTe;
                        //}
                        //else
                        //{
                        //    if (CTSoThucTeOld != null) obj.CTSoThucTe = CTSoThucTeOld;
                        //}

                        //tmpNew = obj.IDHTMT + "_" + obj.IDMucTieu;
                        //if (tmpNew != tmpOld)
                        //{
                        //    tmpOld = tmpNew;
                        //    iRowCT = 1;
                        //    var objNew = DTO.TW_MucTieus.Where(x => x.IDMucTieu == obj.IDMucTieu).SingleOrDefault();
                        //    if (objNew != null)
                        //    {
                        //        switch (objNew.IDTrangThaiDuyet)
                        //        {
                        //            case 10:
                        //            case 8:
                        //            case 7:
                        //            case 5:
                        //            case 4:
                        //            case 2:
                        //                Log += LoiImportKetQua(objNew.MaMucTieu, objNew.IDTrangThaiDuyet.ToString(), 1);
                        //                continue;
                        //        }

                        //        DateTime now = DateTime.Now;
                        //        objNew.LastUpdatedDate = now;
                        //        objNew.LastUpdatedBy = user.UserID;
                        //        objNew.CTSoThucTe = obj.CTSoThucTe;

                        //        DTO.SubmitChanges();
                        //    }
                        //}
                    }
                }

                if (Log.Length > 0)
                {
                    err = "";
                    return WriteLog(user.UserID, FileName, Log);
                }
                return "";
            }
        }
        catch (Exception ex)
        {
            err = step + ": " + ex.Message;
        }
        return "";
    }
    public static string Import_ChucDanh(string path, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        string step = "";
        List<ObjectMucTieuSapXep> ListSapXep = new List<ObjectMucTieuSapXep>();
        ObjectMucTieuSapXep objSapXep = new ObjectMucTieuSapXep();
        string FileName = "Import: ";
        try
        {
            int iFromRow = 8;
            step = "uploads";
            if (!Directory.Exists("uploads")) Directory.CreateDirectory("uploads");

            step = "ExcelCommercial";
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            step = "ExcelPackage";

            DTOBase b = new DTOBase();
            var _connection = b._connection;

            string Log = "";
            int iRowCT = 1;
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                string MaMucTieuError = "";
                var xlFile = new FileInfo(path);
                using (var package = new ExcelPackage(xlFile))
                {
                    step = "ExcelWorkbook";
                    FileName = xlFile.Name;
                    //Add a new worksheet to the empty workbook
                    step = "ExcelWorksheet";
                    var worksheet = package.Workbook.Worksheets[0];

                    int colCount = worksheet.Dimension.End.Column;  //get Column Count
                    int rowCount = worksheet.Dimension.End.Row;     //get row count

                    //TW_MucTieuBase obj = new TW_MucTieuBase();

                    string tmpOld = "";
                    string tmpNew = "";

                    ObjectDDL objHTMT = new ObjectDDL();
                    objHTMT.id = 0;
                    objHTMT.text = "";

                    long? IDHTMTOld = null;
                    long IDMucTieuOld = 0;
                    string CTSoThucTeOld = "";

                    for (int iRow = iFromRow; iRow <= rowCount; iRow++)
                    {
                        bool bError = false;
                        //obj = new TW_MucTieuBase();

                        //int iCol = 2;
                        //var cell = worksheet.Cells[iRow, iCol];
                        //object val = cell.Value; iCol++;//[MaHTCT]
                        //if (!IsNull(val))
                        //{
                        //    if (val.ToString() != objHTMT.text)
                        //    {
                        //        var tmp = DTO.TW_HeThongMucTieus.Where(x => x.IDKhachHang == user.IDKhachHang && (x.IsDelete == false || x.IsDelete == null) && x.MaHTMT.ToLower() == val.ToString().ToLower().Trim()).FirstOrDefault();
                        //        if (tmp != null)
                        //        {
                        //            obj.IDHTMT = tmp.IDHTMT;
                        //            objHTMT.id = tmp.IDHTMT;
                        //            objHTMT.text = tmp.MaHTMT;
                        //            if (IDHTMTOld != obj.IDHTMT)
                        //                IDHTMTOld = obj.IDHTMT;
                        //        }
                        //        else
                        //        {
                        //            bError = true;
                        //            Log += cell.Address + " - " + ErrorNotExit(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //        }
                        //    }
                        //    else obj.IDHTMT = objHTMT.id;
                        //}
                        //else
                        //{
                        //    if (IDHTMTOld != null) obj.IDHTMT = IDHTMTOld;
                        //    else
                        //    {
                        //        bError = true;
                        //        Log += cell.Address + " - " + ErrorNull(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //        continue;
                        //    }
                        //}

                        //cell = worksheet.Cells[iRow, iCol]; val = cell.Value; iCol++;//[MaChiTieu]
                        //if (!IsNull(val))
                        //{
                        //    var tmp = DTO.TW_MucTieus.Where(x => x.IDHTMT == obj.IDHTMT && (x.IsDelete == false || x.IsDelete == null) && x.MaMucTieu.ToLower() == val.ToString().ToLower().Trim()).FirstOrDefault();
                        //    if (tmp != null)
                        //    {
                        //        obj.IDMucTieu = tmp.IDMucTieu;
                        //        if (IDMucTieuOld != obj.IDMucTieu)
                        //            IDMucTieuOld = obj.IDMucTieu;
                        //    }
                        //    else
                        //    {
                        //        bError = true;
                        //        Log += cell.Address + " - " + ErrorNotExit(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //    }

                        //}
                        //else
                        //{
                        //    if (IDMucTieuOld != 0) obj.IDMucTieu = IDMucTieuOld;
                        //    else
                        //    {
                        //        bError = true;
                        //        Log += cell.Address + " - " + ErrorNull(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //        continue;
                        //    }
                        //}

                        //cell = worksheet.Cells[iRow, iCol]; val = cell.Value; iCol++;//[TenChiTieu]

                        //cell = worksheet.Cells[iRow, iCol]; val = cell.Value; iCol++;//[CongThucTinhSoThucTe]
                        //if (!IsNull(val))
                        //{
                        //    obj.CTSoThucTe = getVal(val);
                        //    if (CTSoThucTeOld != obj.CTSoThucTe)
                        //        CTSoThucTeOld = obj.CTSoThucTe;
                        //}
                        //else
                        //{
                        //    if (CTSoThucTeOld != null) obj.CTSoThucTe = CTSoThucTeOld;
                        //}

                        //tmpNew = obj.IDHTMT + "_" + obj.IDMucTieu;
                        //if (tmpNew != tmpOld)
                        //{
                        //    tmpOld = tmpNew;
                        //    iRowCT = 1;
                        //    var objNew = DTO.TW_MucTieus.Where(x => x.IDMucTieu == obj.IDMucTieu).SingleOrDefault();
                        //    if (objNew != null)
                        //    {
                        //        switch (objNew.IDTrangThaiDuyet)
                        //        {
                        //            case 10:
                        //            case 8:
                        //            case 7:
                        //            case 5:
                        //            case 4:
                        //            case 2:
                        //                Log += LoiImportKetQua(objNew.MaMucTieu, objNew.IDTrangThaiDuyet.ToString(), 1);
                        //                continue;
                        //        }

                        //        DateTime now = DateTime.Now;
                        //        objNew.LastUpdatedDate = now;
                        //        objNew.LastUpdatedBy = user.UserID;
                        //        objNew.CTSoThucTe = obj.CTSoThucTe;

                        //        DTO.SubmitChanges();
                        //    }
                        //}
                    }
                }

                if (Log.Length > 0)
                {
                    err = "";
                    return WriteLog(user.UserID, FileName, Log);
                }
                return "";
            }
        }
        catch (Exception ex)
        {
            err = step + ": " + ex.Message;
        }
        return "";
    }
    public static string Import_NhanSu(string path, ObjectPager pager, ObjectAspUser user, ref string err)
    {
        string step = "";
        List<ObjectMucTieuSapXep> ListSapXep = new List<ObjectMucTieuSapXep>();
        ObjectMucTieuSapXep objSapXep = new ObjectMucTieuSapXep();
        string FileName = "Import: ";
        try
        {
            int iFromRow = 8;
            step = "uploads";
            if (!Directory.Exists("uploads")) Directory.CreateDirectory("uploads");

            step = "ExcelCommercial";
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            step = "ExcelPackage";

            DTOBase b = new DTOBase();
            var _connection = b._connection;

            string Log = "";
            int iRowCT = 1;
            using (var DTO = new DTODataContext(_connection))
            {
                DTO.CommandTimeout = 0;
                string MaMucTieuError = "";
                var xlFile = new FileInfo(path);
                using (var package = new ExcelPackage(xlFile))
                {
                    step = "ExcelWorkbook";
                    FileName = xlFile.Name;
                    //Add a new worksheet to the empty workbook
                    step = "ExcelWorksheet";
                    var worksheet = package.Workbook.Worksheets[0];

                    int colCount = worksheet.Dimension.End.Column;  //get Column Count
                    int rowCount = worksheet.Dimension.End.Row;     //get row count

                    //TW_MucTieuBase obj = new TW_MucTieuBase();

                    string tmpOld = "";
                    string tmpNew = "";

                    ObjectDDL objHTMT = new ObjectDDL();
                    objHTMT.id = 0;
                    objHTMT.text = "";

                    long? IDHTMTOld = null;
                    long IDMucTieuOld = 0;
                    string CTSoThucTeOld = "";

                    for (int iRow = iFromRow; iRow <= rowCount; iRow++)
                    {
                        bool bError = false;
                        //obj = new TW_MucTieuBase();

                        //int iCol = 2;
                        //var cell = worksheet.Cells[iRow, iCol];
                        //object val = cell.Value; iCol++;//[MaHTCT]
                        //if (!IsNull(val))
                        //{
                        //    if (val.ToString() != objHTMT.text)
                        //    {
                        //        var tmp = DTO.TW_HeThongMucTieus.Where(x => x.IDKhachHang == user.IDKhachHang && (x.IsDelete == false || x.IsDelete == null) && x.MaHTMT.ToLower() == val.ToString().ToLower().Trim()).FirstOrDefault();
                        //        if (tmp != null)
                        //        {
                        //            obj.IDHTMT = tmp.IDHTMT;
                        //            objHTMT.id = tmp.IDHTMT;
                        //            objHTMT.text = tmp.MaHTMT;
                        //            if (IDHTMTOld != obj.IDHTMT)
                        //                IDHTMTOld = obj.IDHTMT;
                        //        }
                        //        else
                        //        {
                        //            bError = true;
                        //            Log += cell.Address + " - " + ErrorNotExit(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //        }
                        //    }
                        //    else obj.IDHTMT = objHTMT.id;
                        //}
                        //else
                        //{
                        //    if (IDHTMTOld != null) obj.IDHTMT = IDHTMTOld;
                        //    else
                        //    {
                        //        bError = true;
                        //        Log += cell.Address + " - " + ErrorNull(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //        continue;
                        //    }
                        //}

                        //cell = worksheet.Cells[iRow, iCol]; val = cell.Value; iCol++;//[MaChiTieu]
                        //if (!IsNull(val))
                        //{
                        //    var tmp = DTO.TW_MucTieus.Where(x => x.IDHTMT == obj.IDHTMT && (x.IsDelete == false || x.IsDelete == null) && x.MaMucTieu.ToLower() == val.ToString().ToLower().Trim()).FirstOrDefault();
                        //    if (tmp != null)
                        //    {
                        //        obj.IDMucTieu = tmp.IDMucTieu;
                        //        if (IDMucTieuOld != obj.IDMucTieu)
                        //            IDMucTieuOld = obj.IDMucTieu;
                        //    }
                        //    else
                        //    {
                        //        bError = true;
                        //        Log += cell.Address + " - " + ErrorNotExit(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //    }

                        //}
                        //else
                        //{
                        //    if (IDMucTieuOld != 0) obj.IDMucTieu = IDMucTieuOld;
                        //    else
                        //    {
                        //        bError = true;
                        //        Log += cell.Address + " - " + ErrorNull(worksheet.Cells[iFromRow - 1, iCol - 1].Value) + Environment.NewLine;
                        //        continue;
                        //    }
                        //}

                        //cell = worksheet.Cells[iRow, iCol]; val = cell.Value; iCol++;//[TenChiTieu]

                        //cell = worksheet.Cells[iRow, iCol]; val = cell.Value; iCol++;//[CongThucTinhSoThucTe]
                        //if (!IsNull(val))
                        //{
                        //    obj.CTSoThucTe = getVal(val);
                        //    if (CTSoThucTeOld != obj.CTSoThucTe)
                        //        CTSoThucTeOld = obj.CTSoThucTe;
                        //}
                        //else
                        //{
                        //    if (CTSoThucTeOld != null) obj.CTSoThucTe = CTSoThucTeOld;
                        //}

                        //tmpNew = obj.IDHTMT + "_" + obj.IDMucTieu;
                        //if (tmpNew != tmpOld)
                        //{
                        //    tmpOld = tmpNew;
                        //    iRowCT = 1;
                        //    var objNew = DTO.TW_MucTieus.Where(x => x.IDMucTieu == obj.IDMucTieu).SingleOrDefault();
                        //    if (objNew != null)
                        //    {
                        //        switch (objNew.IDTrangThaiDuyet)
                        //        {
                        //            case 10:
                        //            case 8:
                        //            case 7:
                        //            case 5:
                        //            case 4:
                        //            case 2:
                        //                Log += LoiImportKetQua(objNew.MaMucTieu, objNew.IDTrangThaiDuyet.ToString(), 1);
                        //                continue;
                        //        }

                        //        DateTime now = DateTime.Now;
                        //        objNew.LastUpdatedDate = now;
                        //        objNew.LastUpdatedBy = user.UserID;
                        //        objNew.CTSoThucTe = obj.CTSoThucTe;

                        //        DTO.SubmitChanges();
                        //    }
                        //}
                    }
                }

                if (Log.Length > 0)
                {
                    err = "";
                    return WriteLog(user.UserID, FileName, Log);
                }
                return "";
            }
        }
        catch (Exception ex)
        {
            err = step + ": " + ex.Message;
        }
        return "";
    }
    public static string export_CoCauToChuc(List<SYS_CoCauBase> list, ObjectAspUser user, ref string err)
    {
        string step = "";
        int iFromRow = 8;
        int iFromCol = 2;
        try
        {
            step = "tmp";
            if (!Directory.Exists("tmp")) Directory.CreateDirectory("tmp");

            string pathUser = "tmp/" + user.UserID;
            if (!Directory.Exists(pathUser)) Directory.CreateDirectory(pathUser);

            step = "ExcelCommercial";
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            step = "ExcelPackage";

            string FileName = "Export_DanhSachDonVi";//Tạo file mẫu danh sách đơn vị

            string pathSource = "Templates/" + FileName + ".xlsx";
            string pathNew = pathUser + "/" + FileName + "_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xlsx";
            File.Copy(pathSource, pathNew);

            var xlFile = new FileInfo(pathNew);
            using (var package = new ExcelPackage(xlFile))
            {
                step = "ExcelWorkbook";
                step = "ExcelWorksheet";
                var worksheet = package.Workbook.Worksheets[0];

                var maxMucTieu = list.Count();
                int iRow;

                if (maxMucTieu > 3)
                {
                    int maxRow = maxMucTieu + iFromRow;

                    if (maxMucTieu > 34)
                    {
                        int footerRow = 38;
                        worksheet.Cells["A" + footerRow.ToString() + ":BA" + footerRow.ToString()].Copy(worksheet.Cells["A" + (maxRow + 5).ToString() + ":BA" + (maxRow + 5).ToString() + ""]);
                    }

                    worksheet.Cells["A10:BA10"].Copy(worksheet.Cells["A" + (maxRow - 1).ToString() + ":BA" + (maxRow - 1).ToString() + ""]);
                    for (int i = 0; i < maxMucTieu - 3; i++)
                    {
                        iRow = i + 2 + iFromRow;
                        worksheet.Cells["A9:BA9"].Copy(worksheet.Cells["A" + iRow + ":BA" + iRow + ""]);
                    }
                }

                //if (chuThe == 1)
                //{//Cá nhân
                //    worksheet.Cells["I5"].Value = MaHTMT;
                //    worksheet.Cells["AR5"].Value = KyDanhGia;
                //    worksheet.Cells["V5"].Value = TenBoPhan;
                //}
                //else
                //{//Đơn vị
                //    worksheet.Cells["I5"].Value = MaHTMT;
                //    worksheet.Cells["AR5"].Value = KyDanhGia;
                //}
                //Fill header
                //for (int i = 0; i < listNhomMucTieu.Count(); i++)
                //{
                //    switch (i)
                //    {
                //        case 0: worksheet.Cells["V" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 1: worksheet.Cells["Y" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 2: worksheet.Cells["AB" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 3: worksheet.Cells["AE" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 4: worksheet.Cells["AH" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //    }
                //}
                //Fill data
                //for (int i = 0; i < maxMucTieu; i++)
                //{
                //    iRow = i + iFromRow;
                //    int iCol = iFromCol;
                //    var obj = list[i];

                //    if (chuThe == 1)
                //    {
                //        worksheet.Cells["B" + iRow].Value = obj.MaNhanSu;
                //        worksheet.Cells["F" + iRow].Value = obj.HoVaTen;
                //        worksheet.Cells["N" + iRow].Value = obj.TenChucDanh;
                //    }
                //    else
                //    {
                //        worksheet.Cells["B" + iRow].Value = obj.MaCoCau;
                //        worksheet.Cells["F" + iRow].Value = obj.TenCoCau;
                //        worksheet.Cells["N" + iRow].Value = obj.HoVaTen;
                //    }
                //    worksheet.Cells["V" + iRow].Value = obj.Diem1;
                //    worksheet.Cells["Y" + iRow].Value = obj.Diem2;
                //    worksheet.Cells["AB" + iRow].Value = obj.Diem3;
                //    worksheet.Cells["AE" + iRow].Value = obj.Diem4;
                //    worksheet.Cells["AH" + iRow].Value = obj.Diem5;
                //    worksheet.Cells["AK" + iRow].Value = obj.Diem;
                //    worksheet.Cells["AN" + iRow].Value = obj.MucDanhGia;
                //    worksheet.Cells["AQ" + iRow].Value = obj.MucDuyet;
                //    worksheet.Cells["AT" + iRow].Value = obj.NhanXet;
                //}
                //Export Data
                package.Save();
                return xlFile.Name;
            }
        }
        catch (Exception ex)
        {
            err = step + ": " + ex.Message;
        }
        return "";
    }
    public static string export_CoCauChucDanh(List<SYS_ChucDanhBase> list, ObjectAspUser user, ref string err)
    {
        string step = "";
        int iFromRow = 8;
        int iFromCol = 2;
        try
        {
            step = "tmp";
            if (!Directory.Exists("tmp")) Directory.CreateDirectory("tmp");

            string pathUser = "tmp/" + user.UserID;
            if (!Directory.Exists(pathUser)) Directory.CreateDirectory(pathUser);

            step = "ExcelCommercial";
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            step = "ExcelPackage";

            string FileName = "Export_DanhSachChucDanh";//Tạo file mẫu danh sách chức danh

            string pathSource = "Templates/" + FileName + ".xlsx";
            string pathNew = pathUser + "/" + FileName + "_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xlsx";
            File.Copy(pathSource, pathNew);

            var xlFile = new FileInfo(pathNew);
            using (var package = new ExcelPackage(xlFile))
            {
                step = "ExcelWorkbook";
                step = "ExcelWorksheet";
                var worksheet = package.Workbook.Worksheets[0];

                var maxMucTieu = list.Count();
                int iRow;

                if (maxMucTieu > 3)
                {
                    int maxRow = maxMucTieu + iFromRow;

                    if (maxMucTieu > 34)
                    {
                        int footerRow = 38;
                        worksheet.Cells["A" + footerRow.ToString() + ":BA" + footerRow.ToString()].Copy(worksheet.Cells["A" + (maxRow + 5).ToString() + ":BA" + (maxRow + 5).ToString() + ""]);
                    }

                    worksheet.Cells["A10:BA10"].Copy(worksheet.Cells["A" + (maxRow - 1).ToString() + ":BA" + (maxRow - 1).ToString() + ""]);
                    for (int i = 0; i < maxMucTieu - 3; i++)
                    {
                        iRow = i + 2 + iFromRow;
                        worksheet.Cells["A9:BA9"].Copy(worksheet.Cells["A" + iRow + ":BA" + iRow + ""]);
                    }
                }

                //if (chuThe == 1)
                //{//Cá nhân
                //    worksheet.Cells["I5"].Value = MaHTMT;
                //    worksheet.Cells["AR5"].Value = KyDanhGia;
                //    worksheet.Cells["V5"].Value = TenBoPhan;
                //}
                //else
                //{//Đơn vị
                //    worksheet.Cells["I5"].Value = MaHTMT;
                //    worksheet.Cells["AR5"].Value = KyDanhGia;
                //}
                //Fill header
                //for (int i = 0; i < listNhomMucTieu.Count(); i++)
                //{
                //    switch (i)
                //    {
                //        case 0: worksheet.Cells["V" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 1: worksheet.Cells["Y" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 2: worksheet.Cells["AB" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 3: worksheet.Cells["AE" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 4: worksheet.Cells["AH" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //    }
                //}
                //Fill data
                //for (int i = 0; i < maxMucTieu; i++)
                //{
                //    iRow = i + iFromRow;
                //    int iCol = iFromCol;
                //    var obj = list[i];

                //    if (chuThe == 1)
                //    {
                //        worksheet.Cells["B" + iRow].Value = obj.MaNhanSu;
                //        worksheet.Cells["F" + iRow].Value = obj.HoVaTen;
                //        worksheet.Cells["N" + iRow].Value = obj.TenChucDanh;
                //    }
                //    else
                //    {
                //        worksheet.Cells["B" + iRow].Value = obj.MaCoCau;
                //        worksheet.Cells["F" + iRow].Value = obj.TenCoCau;
                //        worksheet.Cells["N" + iRow].Value = obj.HoVaTen;
                //    }
                //    worksheet.Cells["V" + iRow].Value = obj.Diem1;
                //    worksheet.Cells["Y" + iRow].Value = obj.Diem2;
                //    worksheet.Cells["AB" + iRow].Value = obj.Diem3;
                //    worksheet.Cells["AE" + iRow].Value = obj.Diem4;
                //    worksheet.Cells["AH" + iRow].Value = obj.Diem5;
                //    worksheet.Cells["AK" + iRow].Value = obj.Diem;
                //    worksheet.Cells["AN" + iRow].Value = obj.MucDanhGia;
                //    worksheet.Cells["AQ" + iRow].Value = obj.MucDuyet;
                //    worksheet.Cells["AT" + iRow].Value = obj.NhanXet;
                //}
                //Export Data
                package.Save();
                return xlFile.Name;
            }
        }
        catch (Exception ex)
        {
            err = step + ": " + ex.Message;
        }
        return "";
    }
    public static string export_CoCauNhanSu(List<SYS_NhanSuBase> list, ObjectAspUser user, ref string err)
    {
        string step = "";
        int iFromRow = 8;
        int iFromCol = 2;
        try
        {
            step = "tmp";
            if (!Directory.Exists("tmp")) Directory.CreateDirectory("tmp");

            string pathUser = "tmp/" + user.UserID;
            if (!Directory.Exists(pathUser)) Directory.CreateDirectory(pathUser);

            step = "ExcelCommercial";
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            step = "ExcelPackage";

            string FileName = "Export_DanhSachNhanSu";//Tạo file mẫu danh sách nhân sự

            string pathSource = "Templates/" + FileName + ".xlsx";
            string pathNew = pathUser + "/" + FileName + "_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xlsx";
            File.Copy(pathSource, pathNew);

            var xlFile = new FileInfo(pathNew);
            using (var package = new ExcelPackage(xlFile))
            {
                step = "ExcelWorkbook";
                step = "ExcelWorksheet";
                var worksheet = package.Workbook.Worksheets[0];

                var maxMucTieu = list.Count();
                int iRow;

                if (maxMucTieu > 3)
                {
                    int maxRow = maxMucTieu + iFromRow;

                    if (maxMucTieu > 34)
                    {
                        int footerRow = 38;
                        worksheet.Cells["A" + footerRow.ToString() + ":BA" + footerRow.ToString()].Copy(worksheet.Cells["A" + (maxRow + 5).ToString() + ":BA" + (maxRow + 5).ToString() + ""]);
                    }

                    worksheet.Cells["A10:BA10"].Copy(worksheet.Cells["A" + (maxRow - 1).ToString() + ":BA" + (maxRow - 1).ToString() + ""]);
                    for (int i = 0; i < maxMucTieu - 3; i++)
                    {
                        iRow = i + 2 + iFromRow;
                        worksheet.Cells["A9:BA9"].Copy(worksheet.Cells["A" + iRow + ":BA" + iRow + ""]);
                    }
                }

                //if (chuThe == 1)
                //{//Cá nhân
                //    worksheet.Cells["I5"].Value = MaHTMT;
                //    worksheet.Cells["AR5"].Value = KyDanhGia;
                //    worksheet.Cells["V5"].Value = TenBoPhan;
                //}
                //else
                //{//Đơn vị
                //    worksheet.Cells["I5"].Value = MaHTMT;
                //    worksheet.Cells["AR5"].Value = KyDanhGia;
                //}
                //Fill header
                //for (int i = 0; i < listNhomMucTieu.Count(); i++)
                //{
                //    switch (i)
                //    {
                //        case 0: worksheet.Cells["V" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 1: worksheet.Cells["Y" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 2: worksheet.Cells["AB" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 3: worksheet.Cells["AE" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //        case 4: worksheet.Cells["AH" + (iFromRow - 1)].Value = listNhomMucTieu[i].text; break;
                //    }
                //}
                //Fill data
                //for (int i = 0; i < maxMucTieu; i++)
                //{
                //    iRow = i + iFromRow;
                //    int iCol = iFromCol;
                //    var obj = list[i];

                //    if (chuThe == 1)
                //    {
                //        worksheet.Cells["B" + iRow].Value = obj.MaNhanSu;
                //        worksheet.Cells["F" + iRow].Value = obj.HoVaTen;
                //        worksheet.Cells["N" + iRow].Value = obj.TenChucDanh;
                //    }
                //    else
                //    {
                //        worksheet.Cells["B" + iRow].Value = obj.MaCoCau;
                //        worksheet.Cells["F" + iRow].Value = obj.TenCoCau;
                //        worksheet.Cells["N" + iRow].Value = obj.HoVaTen;
                //    }
                //    worksheet.Cells["V" + iRow].Value = obj.Diem1;
                //    worksheet.Cells["Y" + iRow].Value = obj.Diem2;
                //    worksheet.Cells["AB" + iRow].Value = obj.Diem3;
                //    worksheet.Cells["AE" + iRow].Value = obj.Diem4;
                //    worksheet.Cells["AH" + iRow].Value = obj.Diem5;
                //    worksheet.Cells["AK" + iRow].Value = obj.Diem;
                //    worksheet.Cells["AN" + iRow].Value = obj.MucDanhGia;
                //    worksheet.Cells["AQ" + iRow].Value = obj.MucDuyet;
                //    worksheet.Cells["AT" + iRow].Value = obj.NhanXet;
                //}
                //Export Data
                package.Save();
                return xlFile.Name;
            }
        }
        catch (Exception ex)
        {
            err = step + ": " + ex.Message;
        }
        return "";
    }
    #endregion

    #region Message
    public static string LoiImportKetQua(string code, string err, byte lan)
    {
        switch (err)
        {
            case "-99": return "[" + code + "] - Đã duyệt đánh giá tổng hợp" + Environment.NewLine;
            case "-98": return "[" + code + "] - Đã duyệt đánh giá" + Environment.NewLine;
            case "-10": return "[" + code + "] - Đã duyệt cấp 3" + Environment.NewLine;
            case "-8": return "[" + code + "] - Không duyệt cấp 3" + Environment.NewLine;
            case "-7": return "[" + code + "] - Đã duyệt cấp 2" + Environment.NewLine;
            case "-5": return "[" + code + "] - Không duyệt cấp 2" + Environment.NewLine;
            case "-4": return "[" + code + "] - Đã duyệt cấp 1" + Environment.NewLine;
            case "-2": return "[" + code + "] - Không duyệt cấp 1" + Environment.NewLine;
            default: return "[" + code + "] - " + err + Environment.NewLine;
        }
    }
    public static string LoiCongThucTinhDiem(string code, string congThucGoc, byte lan)
    {
        return "[" + code + "] - Lỗi công thức tính điểm chỉ tiêu - " + congThucGoc + Environment.NewLine;
    }
    public static string LoiQuyenImport(string code)
    {
        return "[" + code + "] không có quyền Import";
    }
    public static string LoiQuyenNhap(string code)
    {
        return "[" + code + "] không có quyền nhập";
    }
    public static string LoiQuyenDuyet(string code)
    {
        return "[" + code + "] không có quyền duyệt";
    }
    public static string LoiDaDuyet(string code)
    {
        return "Không được xóa: [" + code + "] đã được duyệt";
    }
    
    public static string LoiXoaMucTieu(string code, string err, byte lan)
    {
        switch (err)
        {
            case "10": return code + " - Đã duyệt cấp 3" + Environment.NewLine;
            case "9": return code + " - Trả về cấp 3" + Environment.NewLine;
            case "7": return code + " - Đã duyệt cấp 2" + Environment.NewLine;
            case "6": return code + " - Trả về cấp 2" + Environment.NewLine;
            case "4": return code + " - Đã duyệt cấp 1" + Environment.NewLine;
            case "3": return code + " - Trả về cấp 1" + Environment.NewLine;
            default: return code + " - " + err + Environment.NewLine;
        }
    }
    public static string IsDuplicateCode()
    {
        return "Lỗi trùng mã";
    }
    public static string IsDuplicateNamTaiChinh(string code)
    {
        return "Lỗi trùng năm tài chính [" + code + "]";
    }
    public static string ErrorNotCorrect(object text)
    {
        return text.ToString() + " không đúng kiểu dữ liệu";
    }
    public static string ErrorNull(object text)
    {
        return text.ToString() + " bắt buộc phải nhập";
    }
    public static string ErrorNotExit(object text)
    {
        return text.ToString() + " không tồn tại";
    }
    public static string ErrorDuplicateChiTieu(string MaChiTieu, string TenChiTieu, string MaNhanSu, string TenNhanSu, string MaCoCau, string TenCoCau)
    {
        if (string.IsNullOrEmpty(MaCoCau))
            return "Chỉ tiêu [" + MaChiTieu + "] đã có: \t[" + MaChiTieu + " - " + TenChiTieu + "]\t[Cá nhân]\t[" + MaNhanSu + " - " + TenNhanSu + "]";
        else return "Chỉ tiêu [" + MaChiTieu + "] đã có: \t[" + MaChiTieu + " - " + TenChiTieu + "]\t[" + MaCoCau + " - " + TenCoCau + "]\t[" + MaNhanSu + " - " + TenNhanSu + "]";
    }
    #endregion

    #region "API"
    public static string apiPost(string url, string jsonValue, string token)
    {
        try
        {
            string responseData = "";
            var sentData = System.Text.Encoding.UTF8.GetBytes(jsonValue);
            var req = System.Net.HttpWebRequest.Create(url);
            req.Timeout = 3600000;//1 tiếng
            req.Method = "POST";
            req.ContentType = "application/json";
            req.Headers.Add("Authorization", "Bearer " + token);
            req.ContentLength = sentData.Length;
            using (var stream = req.GetRequestStream())
            {
                stream.Write(sentData, 0, sentData.Length);
            }
            var response = req.GetResponse();
            responseData = new StreamReader(response.GetResponseStream()).ReadToEnd();
            response.Close();
            req.Abort();

            return responseData;
        }
        catch (Exception ex) { string err = ex.Message; return ""; }
    }
    public static string apiGet(string url, string jsonValue)
    {
        try
        {
            var client = new RestClient(url);
            var request = new RestRequest("", Method.Get);
            request.Timeout = 3600000;//1 tiếng
            request.AddHeader("Content-Type", "application/json");
            var sentData = System.Text.Encoding.UTF8.GetBytes(jsonValue);
            request.AddBody(sentData, "application/json");

            var response = client.Execute(request);
            if (response.IsSuccessful)
                return response.Content;
            else return "";
        }
        catch { return ""; }
    }
    public static string apiGet(string url)
    {
        try
        {
            var client = new RestClient(url);
            var request = new RestRequest("", Method.Get);
            request.AddHeader("Content-Type", "application/json");

            var response = client.Execute(request);
            if (response.IsSuccessful)
                return response.Content;
            else return "";
        }
        catch { return ""; }
    }
    #endregion
    #region File
    public static byte[] GetFile(string path)
    {
        System.IO.FileStream fs = System.IO.File.OpenRead(path);
        byte[] data = new byte[fs.Length];
        int br = fs.Read(data, 0, data.Length);
        if (br != fs.Length)
            throw new System.IO.IOException(path);
        try
        {
            fs.Flush();
            fs.Close();
            File.Delete(path);
        }
        catch (Exception ex)
        {
        }
        return data;
    }
    #endregion
    #region "SECURITY"
    static string _passPhrase = "teamw@ooc.vn";
    static string _initVector = "1a2B3c4D5e6F7g8H";
    public static string StringEncrypt(string sQueryString)
    {
        //return sQueryString;
        try
        {
            string passPhrase = _passPhrase;
            string initVector = _initVector;
            RijndaelEnhanced rijndaelKey = new RijndaelEnhanced(passPhrase, initVector);
            return rijndaelKey.Encrypt(sQueryString).Replace("/", "_._").Replace("+", "_,_");
        }
        catch { return sQueryString; }
    }
    public static string StringDecrypt(string sQueryString)
    {
        //return sQueryString;
        try
        {
            string passPhrase = _passPhrase;
            string initVector = _initVector;
            RijndaelEnhanced rijndaelKey = new RijndaelEnhanced(passPhrase, initVector);
            return rijndaelKey.Decrypt(sQueryString.Replace("_._", "/").Replace("_,_", "+"));
        }
        catch { return sQueryString; }
    }
    #endregion
}
