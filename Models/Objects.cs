using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using digiiTalentDTO;
public class ObjectPager
{
	public long? totalRow { get; set; }//Tổng số bản ghi
	public int? pageIndex { get; set; }//Trang số mấy
	public int? pageSize { get; set; } //Hiển thị 20 bản ghi
	public int? idQuyen { get; set; }
	public string keyword { get; set; }
	public System.Nullable<bool> isDelete { get; set; }
}
public class DefaultUser
{
	public long UserID { get; set; }
	public int IDKhachHang { get; set; }
	public string UserCode { get; set; }
	public string UserName { get; set; }
	public string ImagePath { get; set; }
}
public class ObjectAspUser
{
	public long UserID { get; set; }
	public int IDKhachHang { get; set; } 
	public long? IDCoCau { get; set; } 
	public long? IDChucDanh { get; set; }
	public string ListCoCau { get; set; }
	public string ListChucDanh { get; set; }
	public string UserCode { get; set; }
	public string UserName { get; set; }
	public string UserEmail { get; set; }
	public string ImagePath { get; set; }
	public string PassHienTai { get; set; }
	public string PassMoi { get; set; }
	public string ListQuyen { get; set; }
	public string LinkLogin { get; set; }
}
public class ObjectDDL
{
	public long? id { get; set; }
	public string text { get; set; }
}
public class ChildDDL
{
	public long idParent { get; set; }
	public long id { get; set; }
	public string text { get; set; }
}
public class Object2DDL
{
	public long id { get; set; }
	public string text { get; set; }
	public string des { get; set; }
}
public class ObjectGroupDDL
{
	public string text { get; set; }
	public List<ChildDDL> children { get; set; }
}
public class ObjectImageDDL
{
	public long id { get; set; }
	public string text { get; set; }
	public string url { get; set; }
}
public class ObjectNhanSuAllChucDanhDDL
{
	public string id { get; set; }//IDNhanhSu và IDChucDanh
	public string text { get; set; }
	public string maNS { get; set; }//Mã nhân sự
	public long? idCD { get; set; }//ID chức danh
	public string tenCD { get; set; }//Tên chức danh
	public long? idCC { get; set; }//ID đơn vị
	public string tenCC { get; set; }//Tên đơn vị
	public string url { get; set; }
}
public class ObjectNhanSuDDL
{
	public long id { get; set; }
	public string text { get; set; }
	public string maNS { get; set; }//Mã nhân sự
	public long? idCD { get; set; }//ID chức danh
	public string tenCD { get; set; }//Tên chức danh
	public long? idCC { get; set; }//ID đơn vị
	public string tenCC { get; set; }//Tên đơn vị
	public string url { get; set; }
}
public class ObjectCoCauVaNhanSuDDL
{
	public long id { get; set; }
	public string text { get; set; }
	public long? idNS { get; set; }
	public string textNS { get; set; }
	public long? idCD { get; set; }
	public string textCD { get; set; }
	public string url { get; set; }
}
public class ObjectCoCau
{
	public long IDCoCau { get; set; }
	public string MaCoCau { get; set; }
	public string TenCoCau { get; set; }
	public System.Nullable<long> IDCha { get; set; }
	public System.Nullable<bool> SuDung { get; set; }
	public string MoTa { get; set; }
	public System.Nullable<int> IDKhachHang { get; set; }
	public string STT { get; set; }
	public int CapBac { get; set; }
}
public class ObjectFile
{
	public string FileName { get; set; }
	public string FileSize { get; set; }
	public string NguoiTao { get; set; }
	public string NgayTao { get; set; }
	public string FilePath { get; set; }
}
public class ObjectTrongSo
{
	public long? iDHTMT { get; set; }
	public long? iDHTTS { get; set; }
	public long? iDMucTieu { get; set; }
	public long? iDNhomMucTieu { get; set; }
	public long? iDCoCau { get; set; }
	public long? iDNguoiPhuTrach { get; set; }
	public decimal? trongSo { get; set; }
}
public class ObjectNhapKetQua
{
	public long? iDHTMT { get; set; }
	public long? iDMucTieu { get; set; }
	public long? iDNguoiPhuTrach { get; set; }
	public DateTime? NgayHieuLuc { get; set; }
	public decimal? SoThucTeSo { get; set; }
	public DateTime? SoThucTeNgay { get; set; }
	public decimal? SoThucTeTyLe { get; set; }
}
public class ApiObjectLogin
{
	public string access_token { get; set; }
	public int expires_in { get; set; }
	public string refresh_token { get; set; }
}
public class ApiObjectPhanQuyen
{
	public int ActionID { get; set; }
	public int DataType { get; set; }
	public int FormID { get; set; }
	public List<int> ListPermission_BoPhan { get; set; }
}
public class ApiObjectKhachHang
{
	public int ID { get; set; }
	public string Code { get; set; }
	public string Email { get; set; }
	public string Name { get; set; }
	public string Remark { get; set; }
	public bool? IsDeleted { get; set; }
}
public class ApiObjectCoCau
{
	public Int64 ID { get; set; }
	public string Code { get; set; }
	public int IDKhachHang { get; set; }
	public Int64? IDParent { get; set; }
	public string Name { get; set; }
	public string Remark { get; set; }
	public bool? IsDeleted { get; set; }
	public int? Sort { get; set; }
}
public class ApiObjectChucDanh
{
	public Int64 ID { get; set; }
	public string Code { get; set; }
	public Int64? IDDonVi { get; set; }
	public int IDKhachHang { get; set; }
	public Int64? IDParent { get; set; }
	public Boolean? LaQuanLyCongTy { get; set; }
	public Boolean? LaTruongDonVi { get; set; }
	public string Name { get; set; }
	public bool? IsDeleted { get; set; }
}
public class ApiObjectNhanSu
{
	public Int64 ID { get; set; }
	public string Code { get; set; }
	public Int64? IDDonVi { get; set; }
	public Int64? IDChucDanh { get; set; }
	public int IDKhachHang { get; set; }
	public byte? TinhTrang { get; set; }
	//public Boolean LaQuanLyCongTy { get; set; }
	//public Boolean LaTruongDonVi { get; set; }
	public string Ho { get; set; }
	public string Ten { get; set; }
	public string TenDem { get; set; }
	public string ThangNamSinh { get; set; }
	public string Email { get; set; }
	public string Username { get; set; }
	public string ImageNormal { get; set; }
	public string ImageRaw { get; set; }
	public string ImageSmall { get; set; }
	public string NgayHieuLuc { get; set; }
	public string NgayHetHan { get; set; }
	public bool? IsDeleted { get; set; }
	public List<ApiObjectKiemNhiem> ListKiemNhiem { get; set; }
}
public class ApiObjectNamTaiChinh
{
	public Int64 ID { get; set; }
	public int IDKhachHang { get; set; }
	public int Nam { get; set; }
	public DateTime TuNgay { get; set; }
	public DateTime DenNgay { get; set; }
	public bool? IsDeleted { get; set; }
}
public class ApiObjectKiemNhiem
{
	public Int64? ID { get; set; }
	public Int64? IDDonVi { get; set; }
	public string NgayHieuLuc { get; set; }
	public string NgayHetHan { get; set; }
	public bool? IsDeleted { get; set; }
}
public class ObjectMucTieuSapXep
{
	public long? IDHTMT { get; set; }
	public long IDMucTieu { get; set; }
}
public class ChartGauge
{
	public decimal? value { get; set; }
	public long min { get; set; }
	public long max { get; set; }
	public string text { get; set; }
}
public class ObjectChucDanhDanhGia
{
	public long IDChucDanh { get; set; }
	public decimal? TongDiem { get; set; }
}
public class Object_CRM_CTL_Sale
{
	public string projectCode { get; set; }
	public string propertyType { get; set; }
	public string agencyCode { get; set; }
	public string salesmanEmail { get; set; }
	public decimal? totalSales { get; set; }
}
public class Object_CRM_CTL_Revenue
{
	public string projectCode { get; set; }
	public string propertyType { get; set; }
	public string agencyCode { get; set; }
	public string salesmanEmail { get; set; }
	public decimal? totalRevenue { get; set; }
}
public class Object_CRM_CTL_Customer
{
	public string agencyCode { get; set; }
	public string salesmanEmail { get; set; }
	public string statusName { get; set; }
	public Int16? totalCustomer { get; set; }
}
public class Object_CRM_CTL_Property
{
	public string projectCode { get; set; }
	public string propertyType { get; set; }
	public string statusName { get; set; }
	public decimal? totalQuantity { get; set; }
}