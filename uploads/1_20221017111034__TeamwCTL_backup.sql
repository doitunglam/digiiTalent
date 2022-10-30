USE [teamwCTL]
GO
/****** Object:  StoredProcedure [dbo].[sp_BC_LAY_DS_NhanSuTheoXepHang]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_BC_LAY_DS_NhanSuTheoXepHang]
@IDHTMT	bigint = null,
@IDHTTS bigint = null,
@IDCoCau bigint,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDMucDanhGia nvarchar(50);
	DECLARE @STT int;
	DECLARE @i int = 0;

	DECLARE @TMP_CoCau TABLE(IDCoCauPK bigint NOT NULL,
							  MaThuMuc nvarchar(2048),
							  IDCha bigint,
							  CapBac tinyint,
							  TongNhanSu decimal(9,0),
							  TongNhanSuDanhGia decimal(9,0),
							  IDMucBoPhan bigint,
							  MaMucBoPhan nvarchar(50),
							  CanhBao nvarchar(1000),
							  PRIMARY KEY (IDCoCauPK)
							);

	DECLARE @TMP_BaoCaoChiTiet TABLE(IDCoCauPK bigint NOT NULL,
									 IDMucBoPhanPK bigint,
									 IDMucCaNhanPK int,
									 SL decimal(9,0)
									 PRIMARY KEY (IDCoCauPK,IDMucBoPhanPK,IDMucCaNhanPK)
									);
	--------------------BEGIN Mức đánh giá
	DECLARE @TMP_MucDanhGia TABLE(IDMucDanhGiaPK bigint NOT NULL,
							STT int,
							PRIMARY KEY (IDMucDanhGiaPK)
							);
	
	INSERT INTO @TMP_MucDanhGia (IDMucDanhGiaPK,STT)
	SELECT UPPER(IDMucDanhGia), ROW_NUMBER() OVER(ORDER BY DiemDen DESC, DiemTu DESC,IDMucDanhGia) as STT
	FROM TW_MucDanhGia htmt
	WHERE IDKhachHang=@IDKhachHang AND ISNULL(IsDelete,0)=0 AND IDChuThe=1
	ORDER BY DiemDen DESC, DiemTu DESC,IDMucDanhGia;
	--------------------END Mức đánh giá
	
	--------------------BEGIN Quy Che
	DECLARE @TMP_QuyCheDanhGia TABLE(IDQuyChePK bigint NOT NULL,
									IDMucBoPhan bigint NOT NULL,
									TyLeMin	decimal(9, 2),
									TyLeMax	decimal(9, 2),
									ListID	nvarchar(200),
									STT int,
									PRIMARY KEY (IDQuyChePK)
									);
	DECLARE @DateFrom date;
	DECLARE @DateTo date;

	select @DateFrom=BatDau,@DateTo=KetThuc from TW_HeThongTanSuat WHERE IDHTTS=@IDHTTS;
	
	INSERT INTO @TMP_QuyCheDanhGia (IDQuyChePK,IDMucBoPhan,TyLeMin,TyLeMax,ListID,STT)
	SELECT qc.IDQuyChe,qc.IDMucBoPhan,qc.TyLeMin,qc.TyLeMax,qc.ListID+',', ROW_NUMBER() OVER(ORDER BY qc.IDQuyChe) as STT
	FROM TW_QuyCheDanhGia qc
	INNER JOIN TW_MucDanhGia mBP on mBP.IDMucDanhGia=qc.IDMucBoPhan
	--LEFT JOIN (SELECT qct.IDQuyChe, STRING_AGG (CONVERT(NVARCHAR(4000),mCN.MaMucDanhGia), ';') AS MaMucCaNhan
	--			FROM TW_QuyCheDanhGiaChiTiet qct
	--			INNER JOIN TW_MucDanhGia mCN on mCN.IDMucDanhGia=qct.IDMucCaNhan
	--			GROUP BY qct.IDQuyChe) tmp ON tmp.IDQuyChe=qc.IDQuyChe
	WHERE (qc.NgayHieuLuc is null or (qc.NgayHieuLuc is not null and qc.NgayHieuLuc between @DateFrom and @DateTo))
	AND (qc.NgayHetHieuLuc is null or (qc.NgayHetHieuLuc is not null and qc.NgayHetHieuLuc between @DateFrom and @DateTo))
	ORDER BY qc.IDQuyChe;
	--------------------END Quy Che

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	DECLARE @TotalRow int;
	
	DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
	DECLARE @cnt int=1,@cnt_total int=0;

	DECLARE @MaxCount int;
	SELECT @MaxCount=COUNT(*) FROM @TMP_MucDanhGia;
	IF @MaxCount>20
	BEGIN
		SET @MaxCount=20;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
	
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT @TotalRow=COUNT(*)
	from SYS_CoCau cc 
	INNER JOIN TW_HeThongMucTieu htmt on cc.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
	--Kiểm tra Quyền theo setting
	LEFT JOIN @TableID Q1 ON (@IDQuyen=5
		OR (@IDQuyen in (1,2,3,4) AND cc.IDCoCau=Q1.id)
		)
	WHERE htmt.IDKhachHang=@IDKhachHang
	AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
	AND ISNULL(cc.IsDelete,0)=0
	AND ISNULL(cc.SuDung,0)=1
	and htmt.IDHTMT=@IDHTMT
	AND (@IDCoCau IS NULL OR cc.CayThuMuc like '%;' + cast(@IDCoCau as varchar(20)) + ';%');

	INSERT INTO @TMP_CoCau (IDCoCauPK,IDCha,CapBac,MaThuMuc,TongNhanSu,TongNhanSuDanhGia,IDMucBoPhan,MaMucBoPhan,CanhBao)
	SELECT cc.IDCoCau,cc.IDCha,cc.CapBac,cc.MaThuMuc,ISNULL(TongNhanSu,0),ISNULL(TongNhanSuDanhGia,0),mdgBP.IDMucDanhGia,mdgBP.MaMucDanhGia,'' as CanhBao
	FROM SYS_CoCau cc 
	INNER JOIN TW_HeThongMucTieu htmt on cc.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_DanhGia dgBP on cc.IDKhachHang=htmt.IDKhachHang and cc.IDCoCau=dgBP.IDCoCau AND dgBP.IDHTMT=@IDHTMT AND dgBP.IDHTTS = @IDHTTS AND dgBP.IDNguoiPhuTrach<=0 and dgBP.IDChucDanh=0
	LEFT JOIN TW_MucDanhGia mdgBP on mdgBP.IDKhachHang=@IDKhachHang and ISNULL(mdgBP.IsDelete,0)=0 and mdgBP.MaMucDanhGia=UPPER(dgBP.MaMucDanhGia) and mdgBP.IDChuThe=0--CoCau
	LEFT JOIN (SELECT ns.IDCoCau as IDCoCau,count(*) as TongNhanSuDanhGia
				FROM TW_DanhGia dg
				INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=dg.IDNguoiPhuTrach and ns.TrangThai=1 and ISNULL(ns.IsDelete,0)=0
				LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia
				WHERE dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS AND dg.IDCoCau=0 and dg.IDChucDanh=0
				GROUP BY ns.IDCoCau
				) tmpTongDG on tmpTongDG.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT ns.IDCoCau as IDCoCau,count(*) as TongNhanSu
				FROM SYS_NhanSu ns
				WHERE ns.IDKhachHang=@IDKhachHang and ns.TrangThai=1 and ISNULL(ns.IsDelete,0)=0
				GROUP BY ns.IDCoCau
				) tmpTong on tmpTong.IDCoCau=cc.IDCoCau
	WHERE cc.IDKhachHang=@IDKhachHang
	AND htmt.IDHTMT=@IDHTMT
	AND ISNULL(cc.IsDelete,0)=0
	AND ISNULL(cc.SuDung,0)=1;
	
	----------Tính tổng nhân sự trong bảng @TMP_CoCau
	--DECLARE @iCapBac int = 0;
	--SELECT @iCapBac=MAX(CapBac) FROM @TMP_BaoCao;

	--WHILE @iCapBac >0
	--BEGIN
	--	UPDATE @TMP_BaoCao 
	--	SET TongNhanSu=ISNULL(TongNhanSu,0)+OtherTable.SumTongNhanSu,
	--	    TongNhanSuDanhGia=ISNULL(TongNhanSuDanhGia,0)+OtherTable.SumTongNhanSuDanhGia,
	--	    SL1=SL1+ISNULL(OtherTable.SumSL1,0),
	--	    SL2=SL2+ISNULL(OtherTable.SumSL2,0),
	--	    SL3=SL3+ISNULL(OtherTable.SumSL3,0),
	--	    SL4=SL4+ISNULL(OtherTable.SumSL4,0),
	--	    SL5=SL5+ISNULL(OtherTable.SumSL5,0),
	--	    SL6=SL6+ISNULL(OtherTable.SumSL6,0),
	--	    SL7=SL7+ISNULL(OtherTable.SumSL7,0),
	--	    SL8=SL8+ISNULL(OtherTable.SumSL8,0),
	--	    SL9=SL9+ISNULL(OtherTable.SumSL9,0),
	--	    SL10=SL10+ISNULL(OtherTable.SumSL10,0)
	--	FROM (SELECT IDCha as IDChaPK, 
	--	             SUM(TongNhanSu) as SumTongNhanSu,
	--	             SUM(TongNhanSuDanhGia) as SumTongNhanSuDanhGia,
	--				 SUM(SL1) as SumSL1,
	--				 SUM(SL2) as SumSL2,
	--				 SUM(SL3) as SumSL3,
	--				 SUM(SL4) as SumSL4,
	--				 SUM(SL5) as SumSL5,
	--				 SUM(SL6) as SumSL6,
	--				 SUM(SL7) as SumSL7,
	--				 SUM(SL8) as SumSL8,
	--				 SUM(SL9) as SumSL9,
	--				 SUM(SL10) as SumSL10
	--		  FROM @TMP_BaoCao
	--		  GROUP BY IDCha) AS OtherTable
	--	WHERE IDCoCauPK=OtherTable.IDChaPK
	--	AND CapBac=@iCapBac;
	--	SET @iCapBac = @iCapBac - 1
	--END

	INSERT INTO @TMP_BaoCaoChiTiet(IDCoCauPK,IDMucBoPhanPK,IDMucCaNhanPK,SL)
	SELECT cc.IDCoCauPK,ISNULL(cc.IDMucBoPhan,0),tmp.IDMucCaNhan,tmp.SL
	FROM @TMP_CoCau cc
	LEFT JOIN (SELECT ns.IDCoCau as IDCoCau,mdg.IDMucDanhGia as IDMucCaNhan,count(*) as SL
				FROM TW_DanhGia dg
				LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia and dg.IDChucDanh=0
				INNER JOIN TW_MucDanhGia mdg on mdg.IDKhachHang=@IDKhachHang and ISNULL(mdg.IsDelete,0)=0 and mdg.MaMucDanhGia=UPPER(ISNULL(dgth.MucDuyet,dg.MaMucDanhGia)) and mdg.IDChuThe=1--Cá nhân
				--INNER JOIN  @TMP_MucDanhGia tmpDG on tmpDG.STT=1
				INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=dg.IDNguoiPhuTrach and ns.TrangThai=1 and ISNULL(ns.IsDelete,0)=0
				WHERE dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS AND dg.IDCoCau=0 and dg.IDChucDanh=0
				GROUP BY ns.IDCoCau,mdg.IDMucDanhGia
				) tmp on tmp.IDCoCau=cc.IDCoCauPK
	WHERE IDMucCaNhan is not null

	--Canh Bao Quy Che
	--SELECT @iCapBac = 0;
	--SELECT @iCapBac=Count(*) FROM @TMP_QuyCheDanhGia;
	
	--WHILE @iCapBac>0
	--BEGIN

	--	DECLARE @IDQuyChe bigint;
	--	DECLARE @IDMucBoPhan bigint;
	--	DECLARE @TyLeMax decimal(9, 2);
	--	DECLARE @TyLeMin decimal(9, 2);
	--	SELECT @IDQuyChe=IDQuyChePK,@IDMucBoPhan=IDMucBoPhan,@TyLeMax=TyLeMax,@TyLeMin=TyLeMin FROM @TMP_QuyCheDanhGia where STT=@iCapBac;

	--	--IF @TyLeMax IS NOT NULL
	--	--BEGIN
	--	--	UPDATE @TMP_CoCau SET CanhBao=CanhBao+MaMucBoPhan+'>'+Cast(@TyLeMax as nvarchar(20))+', '
	--	--	WHERE (SL1*100/TongNhanSu)>@TyLeMax
	--	--	AND TongNhanSuDanhGia>0 AND IDMucBoPhan=@IDMucBoPhan AND SL1>0 AND IDMucDanhGia1 IN (SELECT IDMucCaNhan FROM TW_QuyCheDanhGiaChiTiet WHERE IDQuyChe=@IDQuyChe)
	--	--END;
		
	--	SET @iCapBac = @iCapBac - 1
	--END

	--Cảnh báo TyLeMax
	UPDATE @TMP_CoCau
	SET CanhBao=CanhBaoQC
	FROM
	(SELECT bcct.IDCoCauPK as IDCoCauQC,bcct.IDMucBoPhanPK,SUM(SL)*100/cc.TongNhanSu as TyLe,qc.TyLeMax,tmp.MaMucCaNhan+' > '+cast(qc.TyLeMax as nvarchar(50)) + '%' as CanhBaoQC
	FROM @TMP_BaoCaoChiTiet bcct
	INNER JOIN @TMP_CoCau cc on cc.IDCoCauPK=bcct.IDCoCauPK and cc.IDMucBoPhan=bcct.IDMucBoPhanPK
	INNER JOIN @TMP_QuyCheDanhGia qc on qc.IDMucBoPhan=bcct.IDMucBoPhanPK
	INNER JOIN TW_QuyCheDanhGiaChiTiet qcct on qcct.IDQuyChe=qc.IDQuyChePK and qcct.IDMucCaNhan=bcct.IDMucCaNhanPK
	LEFT JOIN (SELECT qct.IDQuyChe, STRING_AGG (CONVERT(NVARCHAR(4000),mCN.MaMucDanhGia), '+') AS MaMucCaNhan
				FROM TW_QuyCheDanhGiaChiTiet qct
				INNER JOIN TW_MucDanhGia mCN on mCN.IDMucDanhGia=qct.IDMucCaNhan
				GROUP BY qct.IDQuyChe) tmp ON tmp.IDQuyChe=qc.IDQuyChePK
	WHERE qc.TyLeMax is not null
	GROUP BY bcct.IDCoCauPK,bcct.IDMucBoPhanPK,qc.IDQuyChePK,qc.TyLeMax,cc.TongNhanSu,tmp.MaMucCaNhan
	) OtherTable
	WHERE OtherTable.TyLe>TyLeMax
	AND IDCoCauPK=OtherTable.IDCoCauQC

	--Cảnh báo TyLeMin
	UPDATE @TMP_CoCau
	SET CanhBao=CanhBaoQC
	FROM
	(SELECT bcct.IDCoCauPK as IDCoCauQC,bcct.IDMucBoPhanPK,SUM(SL)*100/cc.TongNhanSu as TyLe,qc.TyLeMin,tmp.MaMucCaNhan+' < '+cast(qc.TyLeMin as nvarchar(50)) + '%' as CanhBaoQC
	FROM @TMP_BaoCaoChiTiet bcct
	INNER JOIN @TMP_CoCau cc on cc.IDCoCauPK=bcct.IDCoCauPK and cc.IDMucBoPhan=bcct.IDMucBoPhanPK
	INNER JOIN @TMP_QuyCheDanhGia qc on qc.IDMucBoPhan=bcct.IDMucBoPhanPK
	INNER JOIN TW_QuyCheDanhGiaChiTiet qcct on qcct.IDQuyChe=qc.IDQuyChePK and qcct.IDMucCaNhan=bcct.IDMucCaNhanPK
	LEFT JOIN (SELECT qct.IDQuyChe, STRING_AGG (CONVERT(NVARCHAR(4000),mCN.MaMucDanhGia), '+') AS MaMucCaNhan
				FROM TW_QuyCheDanhGiaChiTiet qct
				INNER JOIN TW_MucDanhGia mCN on mCN.IDMucDanhGia=qct.IDMucCaNhan
				GROUP BY qct.IDQuyChe) tmp ON tmp.IDQuyChe=qc.IDQuyChePK
	WHERE qc.TyLeMin is not null
	GROUP BY bcct.IDCoCauPK,bcct.IDMucBoPhanPK,qc.IDQuyChePK,qc.TyLeMin,cc.TongNhanSu,tmp.MaMucCaNhan
	) OtherTable
	WHERE OtherTable.TyLe<TyLeMin
	AND IDCoCauPK=OtherTable.IDCoCauQC

	SELECT cc.IDCoCau,cc.MaCoCau,cc.TenCoCau,MaMucBoPhan,CanhBao,tmp.TongNhanSu,tmp.TongNhanSuDanhGia,@TotalRow as TotalRow,
	tmp1.SL as SL1,
	tmp2.SL as SL2,
	tmp3.SL as SL3,
	tmp4.SL as SL4,
	tmp5.SL as SL5,
	tmp6.SL as SL6,
	tmp7.SL as SL7,
	tmp8.SL as SL8,
	tmp9.SL as SL9,
	tmp10.SL as SL10
	FROM @TMP_CoCau tmp
	INNER JOIN SYS_CoCau cc on cc.IDCoCau=tmp.IDCoCauPK
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=1
				) tmp1 on tmp1.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=2
				) tmp2 on tmp2.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=3
				) tmp3 on tmp3.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=4
				) tmp4 on tmp4.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=5
				) tmp5 on tmp5.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=6
				) tmp6 on tmp6.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=7
				) tmp7 on tmp7.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=8
				) tmp8 on tmp8.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=9
				) tmp9 on tmp9.IDCoCau=cc.IDCoCau
	LEFT JOIN (SELECT bcct.IDCoCauPK as IDCoCau,bcct.SL
				FROM @TMP_BaoCaoChiTiet bcct
				INNER JOIN  @TMP_MucDanhGia tmpDG on bcct.IDMucCaNhanPK=tmpDG.IDMucDanhGiaPK 
				WHERE tmpDG.STT=10
				) tmp10 on tmp10.IDCoCau=cc.IDCoCau
	
	--Kiểm tra Quyền theo setting
	LEFT JOIN @TableID Q1 ON (@IDQuyen=5
		OR (@IDQuyen in (1,2,3,4) AND cc.IDCoCau=Q1.id)
		)
	WHERE (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
	AND (@IDCoCau IS NULL OR cc.CayThuMuc like '%;' + cast(@IDCoCau as varchar(20)) + ';%')
	ORDER BY tmp.MaThuMuc
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BC_LAY_DS_ThongKeKetQua]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BC_LAY_DS_ThongKeKetQua]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@ChuThe tinyint,
@IDCoCau bigint,
@IDCoCauPhuTrach bigint,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDHTTS bigint;
	DECLARE @STT int;
	DECLARE @i int = 0;

	DECLARE @TMP_BaoCao TABLE(IDNhanSuPK bigint NOT NULL,
							IDCoCauPK bigint NOT NULL,
							IDChucDanh bigint NULL,
							MucDanhGia nvarchar(50) NULL,
							Diem1 decimal(9, 2) NULL,
							Diem2 decimal(9, 2) NULL,
							Diem3 decimal(9, 2) NULL,
							Diem4 decimal(9, 2) NULL,
							Diem5 decimal(9, 2) NULL,
							Diem6 decimal(9, 2) NULL,
							Diem7 decimal(9, 2) NULL,
							Diem8 decimal(9, 2) NULL,
							Diem9 decimal(9, 2) NULL,
							Diem10 decimal(9, 2) NULL,
							Diem11 decimal(9, 2) NULL,
							Diem12 decimal(9, 2) NULL,
							Diem13 decimal(9, 2) NULL,
							Diem14 decimal(9, 2) NULL,
							Diem15 decimal(9, 2) NULL,
							Diem16 decimal(9, 2) NULL,
							Diem17 decimal(9, 2) NULL,
							Diem18 decimal(9, 2) NULL,
							Diem19 decimal(9, 2) NULL,
							Diem20 decimal(9, 2) NULL,
							MaDG1 nvarchar(50),
							MaDG2 nvarchar(50),
							MaDG3 nvarchar(50),
							MaDG4 nvarchar(50),
							MaDG5 nvarchar(50),
							MaDG6 nvarchar(50),
							MaDG7 nvarchar(50),
							MaDG8 nvarchar(50),
							MaDG9 nvarchar(50),
							MaDG10 nvarchar(50),
							MaDG11 nvarchar(50),
							MaDG12 nvarchar(50),
							MaDG13 nvarchar(50),
							MaDG14 nvarchar(50),
							MaDG15 nvarchar(50),
							MaDG16 nvarchar(50),
							MaDG17 nvarchar(50),
							MaDG18 nvarchar(50),
							MaDG19 nvarchar(50),
							MaDG20 nvarchar(50),
							PRIMARY KEY (IDNhanSuPK,IDCoCauPK)
							);
	DECLARE @TMP_HTTS TABLE(IDHTTS bigint NOT NULL,
							STT int,
							PRIMARY KEY (IDHTTS)
							);

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	DECLARE @TotalRow int;
	
	DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
	DECLARE @cnt int=1,@cnt_total int=0;

	--Lấy danh sách tần suất
	INSERT INTO @TMP_HTTS (IDHTTS,STT)
	SELECT htts.IDHTTS, ROW_NUMBER() OVER(ORDER BY htts.IDLoaiTanSuat, htts.BatDau, htts.TenTanSuat) as STT
	FROM TW_HeThongMucTieu htmt
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTMT=htmt.IDHTMT
	WHERE htmt.IDKhachHang=@IDKhachHang AND ISNULL(htmt.SuDung,0)=1  AND ISNULL(htts.SuDung,0)=1 
	AND ISNULL(htmt.IsDelete,0) = 0
	AND (@IDHTMT is null or (@IDHTMT is not null and ISNULL(htts.IDHTMT,0)=@IDHTMT))
	AND (@IDLoaiTanSuat is null or (@IDLoaiTanSuat is not null and htts.IDLoaiTanSuat=@IDLoaiTanSuat))
	ORDER BY htts.IDLoaiTanSuat, htts.BatDau, htts.TenTanSuat;

	DECLARE @MaxCount int;
	SELECT @MaxCount=COUNT(*) FROM @TMP_HTTS;
	IF @MaxCount>20
	BEGIN
		SET @MaxCount=20;
	END;

	IF @ChuThe = 0
	BEGIN--Theo bộ phận
		
		SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		IF @IDQuyen=1 OR @IDQuyen=2
		INSERT INTO @TableID (id) VALUES (@Q_IDCoCau);
		
		IF @IDQuyen=2 OR @IDQuyen=3
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
				
			--Them Chuc Danh kiem nhiem
			INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
			SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
			FROM SYS_NhanSu ns
			INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
			INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
			INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
			WHERE ns.IDNhanSu=@IDNhanSu;

			SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
			WHILE @cnt <= @cnt_total
			BEGIN
				SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
				IF @CayThuMuc IS NOT NULL 
					INSERT INTO @TableID (id) 
					SELECT cc.IDCoCau 
					from SYS_CoCau cc
					LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
					where cc.IDKhachHang=@IDKhachHang
					AND tmp.id is null
					and cc.CayThuMuc like @CayThuMuc+'%';
				SET @cnt = @cnt + 1;
			END;
		END;

		IF @IDQuyen=4
		BEGIN
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
		END;

		SELECT @TotalRow=COUNT(*)
		from SYS_CoCau cc 
		--LEFT JOIN SYS_ChucDanh cd on cd.IDCoCau=cc.IDCoCau and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
		LEFT JOIN
					(SELECT cd.IDCoCau,cd.IDChucDanh,cd.DB_IDChucDanh, row_number() over (partition by cd.IDCoCau order by cd.DB_IDChucDanh desc) as STT
					FROM SYS_ChucDanh cd 
					WHERE ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
					AND cd.IDKhachHang=@IDKhachHang) cd 
					ON cd.IDCoCau=cc.IDCoCau and cd.STT=1
		LEFT JOIN
					(SELECT ns.IDNhanSu, cd.IDCoCau,cd.IDChucDanh,ns.IDKhachHang, row_number() over (partition by cd.IDChucDanh order by cd.LaCapTruong desc) as STT
					FROM SYS_NhanSu ns
					INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
					WHERE ISNULL(ns.IsDelete,0)=0 and ISNULL(ns.TrangThai,0)=1
					AND ns.IDKhachHang=@IDKhachHang) ns 
					ON ns.IDCoCau=cc.IDCoCau and ns.IDChucDanh=cd.IDChucDanh and ns.IDKhachHang=cc.IDKhachHang and ns.STT=1
		INNER JOIN TW_HeThongMucTieu htmt on cc.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on cc.IDKhachHang=htmt.IDKhachHang and cc.IDCoCau=dg.IDCoCau AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS
		
		WHERE htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND cc.IDCoCau in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (cc.IDCoCau in (select id from @TableID) OR ns.IDCoCau in (select id from @TableID)))
					)
				)
			)
		AND ISNULL(cc.IsDelete,0)=0
		AND ISNULL(cc.SuDung,0)=1
		and htmt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IDCoCau IS NULL OR cc.CayThuMuc like '%;' + cast(@IDCoCau as varchar(20)) + ';%');

		
		INSERT INTO @TMP_BaoCao (IDNhanSuPK,IDChucDanh,IDCoCauPK,MucDanhGia)
		SELECT ISNULL(ns.IDNhanSu,0),ns.IDChucDanh,cc.IDCoCau,dg.MaMucDanhGia
		from SYS_CoCau cc 
		--LEFT JOIN SYS_ChucDanh cd on cd.IDCoCau=cc.IDCoCau and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
		LEFT JOIN
					(SELECT cd.IDCoCau,cd.IDChucDanh,cd.DB_IDChucDanh, row_number() over (partition by cd.IDCoCau order by cd.DB_IDChucDanh desc) as STT
					FROM SYS_ChucDanh cd 
					WHERE ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
					AND cd.IDKhachHang=@IDKhachHang) cd 
					ON cd.IDCoCau=cc.IDCoCau and cd.STT=1
		LEFT JOIN
					(SELECT ns.IDNhanSu, cd.IDCoCau,cd.IDChucDanh,ns.IDKhachHang, row_number() over (partition by cd.IDChucDanh order by cd.LaCapTruong desc) as STT
					FROM SYS_NhanSu ns
					INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
					WHERE ISNULL(ns.IsDelete,0)=0 and ISNULL(ns.TrangThai,0)=1
					AND ns.IDKhachHang=@IDKhachHang) ns 
					ON ns.IDCoCau=cc.IDCoCau and ns.IDChucDanh=cd.IDChucDanh and ns.IDKhachHang=cc.IDKhachHang and ns.STT=1
		INNER JOIN TW_HeThongMucTieu htmt on cc.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on cc.IDKhachHang=htmt.IDKhachHang and cc.IDCoCau=dg.IDCoCau AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS
		WHERE htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND cc.IDCoCau in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (cc.IDCoCau in (select id from @TableID) OR ns.IDCoCau in (select id from @TableID)))
					)
				)
			)
		AND ISNULL(cc.IsDelete,0)=0
		AND ISNULL(cc.SuDung,0)=1
		and htmt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IDCoCau IS NULL OR cc.CayThuMuc like '%;' + cast(@IDCoCau as varchar(20)) + ';%')
		ORDER BY cc.MaThuMuc
		OFFSET (@PageIndex - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;

		--Cập nhật điểm
		SET @i = 0;
		WHILE @i <= @MaxCount
		BEGIN
			SET @i = @i + 1
			SELECT @IDHTTS=IDHTTS,@STT=STT FROM @TMP_HTTS WHERE STT=@i;
			
			IF @STT=1 UPDATE @TMP_BaoCao SET Diem1=OtherTable.Diem, MaDG1=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=2 UPDATE @TMP_BaoCao SET Diem2=OtherTable.Diem, MaDG2=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=3 UPDATE @TMP_BaoCao SET Diem3=OtherTable.Diem, MaDG3=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=4 UPDATE @TMP_BaoCao SET Diem4=OtherTable.Diem, MaDG4=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=5 UPDATE @TMP_BaoCao SET Diem5=OtherTable.Diem, MaDG5=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=6 UPDATE @TMP_BaoCao SET Diem6=OtherTable.Diem, MaDG6=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=7 UPDATE @TMP_BaoCao SET Diem7=OtherTable.Diem, MaDG7=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=8 UPDATE @TMP_BaoCao SET Diem8=OtherTable.Diem, MaDG8=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=9 UPDATE @TMP_BaoCao SET Diem9=OtherTable.Diem, MaDG9=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=10 UPDATE @TMP_BaoCao SET Diem10=OtherTable.Diem, MaDG10=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=11 UPDATE @TMP_BaoCao SET Diem11=OtherTable.Diem, MaDG11=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=12 UPDATE @TMP_BaoCao SET Diem12=OtherTable.Diem, MaDG12=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=13 UPDATE @TMP_BaoCao SET Diem13=OtherTable.Diem, MaDG13=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=14 UPDATE @TMP_BaoCao SET Diem14=OtherTable.Diem, MaDG14=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=15 UPDATE @TMP_BaoCao SET Diem15=OtherTable.Diem, MaDG15=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=16 UPDATE @TMP_BaoCao SET Diem16=OtherTable.Diem, MaDG16=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=17 UPDATE @TMP_BaoCao SET Diem17=OtherTable.Diem, MaDG17=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=18 UPDATE @TMP_BaoCao SET Diem18=OtherTable.Diem, MaDG18=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=19 UPDATE @TMP_BaoCao SET Diem19=OtherTable.Diem, MaDG19=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
			IF @STT=20 UPDATE @TMP_BaoCao SET Diem20=OtherTable.Diem, MaDG20=OtherTable.MaMucDanhGia FROM (SELECT dg.IDCoCau,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau>0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDCoCauPK=OtherTable.IDCoCau;
		END

		SELECT tmp.*, @TotalRow as TotalRow,ns.MaNhanSu,ns.AnhNhanSu,ns.HoVaTen,cc.MaCoCau,cc.TenCoCau,cd.MaChucDanh,cd.TenChucDanh
		FROM @TMP_BaoCao tmp
		LEFT JOIN SYS_NhanSu ns on ns.IDNhanSu=tmp.IDNhanSuPK
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=tmp.IDCoCauPK
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=tmp.IDChucDanh
		ORDER BY cc.MaThuMuc;
	END;
	ELSE
	BEGIN--Theo Nhân sự
		
		SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		IF @IDQuyen=1
		INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
		IF @IDQuyen=2 OR @IDQuyen=3
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
	
			--Them Chuc Danh kiem nhiem
			INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
			SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
			FROM SYS_NhanSu ns
			INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
			INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
			INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
			WHERE ns.IDNhanSu=@IDNhanSu;

			SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
			WHILE @cnt <= @cnt_total
			BEGIN
				SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
				IF @CayThuMuc IS NOT NULL 
					INSERT INTO @TableID (id) 
					SELECT cc.IDCoCau 
					from SYS_CoCau cc
					LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
					where cc.IDKhachHang=@IDKhachHang
					AND tmp.id is null
					and cc.CayThuMuc like @CayThuMuc+'%';
				SET @cnt = @cnt + 1;
			END;
		END;

		IF @IDQuyen=4
		BEGIN
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
		END;

		SELECT @TotalRow=COUNT(*)
		FROM SYS_NhanSu ns
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=ns.IDCoCau
		INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh
		INNER JOIN TW_HeThongMucTieu htmt on ns.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on ns.IDKhachHang=htmt.IDKhachHang and ns.IDNhanSu=dg.IDNguoiPhuTrach AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS
		--Kiểm tra Quyền theo setting
		LEFT JOIN @TableID Q1 ON (@IDQuyen=5
			OR (@IDQuyen=1 AND ns.IDNhanSu=Q1.id)
			OR (@IDQuyen in (2,3,4) AND (ns.IDCoCau=Q1.id))
			)
		WHERE ns.IDKhachHang=@IDKhachHang 
		AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
		and htmt.IDHTMT=@IDHTMT
		AND ISNULL(ns.IsDelete,0)=0
		AND ns.TrangThai=1
		AND (@IDCoCauPhuTrach Is null OR (@IDCoCauPhuTrach is not null and ns.IDCoCau = @IDCoCauPhuTrach))
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ns.IDNhanSu = @IDNguoiPhuTrach))

		INSERT INTO @TMP_BaoCao (IDNhanSuPK,IDChucDanh,IDCoCauPK,MucDanhGia)
		SELECT ns.IDNhanSu,ns.IDChucDanh,ISNULL(ns.IDCoCau,0),dg.MaMucDanhGia
		FROM SYS_NhanSu ns
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=ns.IDCoCau
		INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh
		INNER JOIN TW_HeThongMucTieu htmt on ns.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on ns.IDKhachHang=htmt.IDKhachHang and ns.IDNhanSu=dg.IDNguoiPhuTrach AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS
		--Kiểm tra Quyền theo setting
		LEFT JOIN @TableID Q1 ON (@IDQuyen=5
			OR (@IDQuyen=1 AND ns.IDNhanSu=Q1.id)
			OR (@IDQuyen in (2,3,4) AND (ns.IDCoCau=Q1.id))
			)
		WHERE ns.IDKhachHang=@IDKhachHang 
		AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
		and htmt.IDHTMT=@IDHTMT
		AND ISNULL(ns.IsDelete,0)=0
		AND ns.TrangThai=1
		AND (@IDCoCauPhuTrach Is null OR (@IDCoCauPhuTrach is not null and ns.IDCoCau = @IDCoCauPhuTrach))
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ns.IDNhanSu = @IDNguoiPhuTrach))
		ORDER BY cc.MaThuMuc, cd.MaThuMuc, ns.MaNhanSu
		OFFSET (@PageIndex - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;

		--Cập nhật điểm
		SET @i = 0;
		WHILE @i <= @MaxCount
		BEGIN
			SET @i = @i + 1
			SELECT @IDHTTS=IDHTTS,@STT=STT FROM @TMP_HTTS WHERE STT=@i;
			
			IF @STT=1 UPDATE @TMP_BaoCao SET Diem1=OtherTable.Diem, MaDG1=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=2 UPDATE @TMP_BaoCao SET Diem2=OtherTable.Diem, MaDG2=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=3 UPDATE @TMP_BaoCao SET Diem3=OtherTable.Diem, MaDG3=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=4 UPDATE @TMP_BaoCao SET Diem4=OtherTable.Diem, MaDG4=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=5 UPDATE @TMP_BaoCao SET Diem5=OtherTable.Diem, MaDG5=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=6 UPDATE @TMP_BaoCao SET Diem6=OtherTable.Diem, MaDG6=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=7 UPDATE @TMP_BaoCao SET Diem7=OtherTable.Diem, MaDG7=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=8 UPDATE @TMP_BaoCao SET Diem8=OtherTable.Diem, MaDG8=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=9 UPDATE @TMP_BaoCao SET Diem9=OtherTable.Diem, MaDG9=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=10 UPDATE @TMP_BaoCao SET Diem10=OtherTable.Diem, MaDG10=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=11 UPDATE @TMP_BaoCao SET Diem11=OtherTable.Diem, MaDG11=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=12 UPDATE @TMP_BaoCao SET Diem12=OtherTable.Diem, MaDG12=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=13 UPDATE @TMP_BaoCao SET Diem13=OtherTable.Diem, MaDG13=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=14 UPDATE @TMP_BaoCao SET Diem14=OtherTable.Diem, MaDG14=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=15 UPDATE @TMP_BaoCao SET Diem15=OtherTable.Diem, MaDG15=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=16 UPDATE @TMP_BaoCao SET Diem16=OtherTable.Diem, MaDG16=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=17 UPDATE @TMP_BaoCao SET Diem17=OtherTable.Diem, MaDG17=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=18 UPDATE @TMP_BaoCao SET Diem18=OtherTable.Diem, MaDG18=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=19 UPDATE @TMP_BaoCao SET Diem19=OtherTable.Diem, MaDG19=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
			IF @STT=20 UPDATE @TMP_BaoCao SET Diem20=OtherTable.Diem, MaDG20=OtherTable.MaMucDanhGia FROM (SELECT dg.IDNguoiPhuTrach,ISNULL(dgth.DiemDuyet,dg.Diem) as Diem, ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia FROM TW_DanhGia dg LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia WHERE dg.IDCoCau=0 and dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS) AS OtherTable WHERE IDNhanSuPK=OtherTable.IDNguoiPhuTrach;
		END

		SELECT tmp.*, @TotalRow as TotalRow,ns.MaNhanSu,ns.AnhNhanSu,ns.HoVaTen,cc.MaCoCau,cc.TenCoCau,cd.MaChucDanh,cd.TenChucDanh
		FROM @TMP_BaoCao tmp
		LEFT JOIN SYS_NhanSu ns on ns.IDNhanSu=tmp.IDNhanSuPK
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=tmp.IDCoCauPK
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=tmp.IDChucDanh
		ORDER BY cc.MaThuMuc,cd.MaThuMuc,ns.MaNhanSu
	END;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BC_LAY_DS_ThongKeXepHang]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BC_LAY_DS_ThongKeXepHang]
@IDHTMT	bigint = null,
@IDHTTS	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@ChuThe tinyint,
@IDCoCau bigint,
@IDCoCauPhuTrach bigint,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDXepHang tinyint=1,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @TMP_DanhGiaTongHop TABLE(IDDanhGia bigint NOT NULL,
										IDNhanSu bigint NOT NULL,
										IDCoCau bigint NOT NULL,
										IDChucDanh bigint NULL,
										MucDanhGia nvarchar(50) NULL,
										Diem decimal(9, 2) NULL,
										DiemCongTru decimal(9, 2) NULL,
										TongDiem decimal(9, 2) NULL,
										STT int,
										PRIMARY KEY (IDDanhGia,IDNhanSu,IDCoCau)
									);

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	DECLARE @TotalRow int;
	
	DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
	DECLARE @cnt int=1,@cnt_total int=0;

	IF @ChuThe = 0
	BEGIN--Theo bộ phận
		
		SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		IF @IDQuyen=1 OR @IDQuyen=2
		INSERT INTO @TableID (id) VALUES (@Q_IDCoCau);
		
		IF @IDQuyen=2 OR @IDQuyen=3
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
				
			--Them Chuc Danh kiem nhiem
			INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
			SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
			FROM SYS_NhanSu ns
			INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
			INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
			INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
			WHERE ns.IDNhanSu=@IDNhanSu;

			SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
			WHILE @cnt <= @cnt_total
			BEGIN
				SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
				IF @CayThuMuc IS NOT NULL 
					INSERT INTO @TableID (id) 
					SELECT cc.IDCoCau 
					from SYS_CoCau cc
					LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
					where cc.IDKhachHang=@IDKhachHang
					AND tmp.id is null
					and cc.CayThuMuc like @CayThuMuc+'%';
				SET @cnt = @cnt + 1;
			END;
		END;

		IF @IDQuyen=4
		BEGIN
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
		END;

		SELECT @TotalRow=COUNT(*)
		from SYS_CoCau cc 
		LEFT JOIN SYS_ChucDanh cd on cd.IDCoCau=cc.IDCoCau and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
		LEFT JOIN
					(SELECT ns.IDNhanSu, cd.IDCoCau,cd.IDChucDanh,ns.IDKhachHang, row_number() over (partition by cd.IDChucDanh order by cd.LaCapTruong desc) as STT
					FROM SYS_NhanSu ns
					INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
					WHERE ISNULL(ns.IsDelete,0)=0 and ISNULL(ns.TrangThai,0)=1
					AND ns.IDKhachHang=@IDKhachHang) ns 
					ON ns.IDCoCau=cc.IDCoCau and ns.IDChucDanh=cd.IDChucDanh and ns.IDKhachHang=cc.IDKhachHang and ns.STT=1
		INNER JOIN TW_HeThongMucTieu htmt on cc.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on cc.IDKhachHang=htmt.IDKhachHang and cc.IDCoCau=dg.IDCoCau AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS AND dg.IDNguoiPhuTrach<=0
		WHERE htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND cc.IDCoCau in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (cc.IDCoCau in (select id from @TableID) OR ns.IDCoCau in (select id from @TableID)))
					)
				)
			)
		AND ISNULL(cc.IsDelete,0)=0
		AND ISNULL(cc.SuDung,0)=1
		and htmt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IDCoCau IS NULL OR cc.CayThuMuc like '%;' + cast(@IDCoCau as varchar(20)) + ';%');

		INSERT INTO @TMP_DanhGiaTongHop (IDNhanSu,IDDanhGia,IDChucDanh,IDCoCau,MucDanhGia,Diem,DiemCongTru,TongDiem,STT)
		SELECT ISNULL(ns.IDNhanSu,0),ISNULL(dg.IDDanhGia,0),cd.IDChucDanh,cc.IDCoCau,dg.MaMucDanhGia,dg.Diem,dg.DiemCongTru,dg.TongDiem,
				row_number() over (order by isnull(isnull(dgth.DiemDuyet,dg.TongDiem),0) desc, cc.MaThuMuc) as STT
		from SYS_CoCau cc 
		LEFT JOIN SYS_ChucDanh cd on cd.IDCoCau=cc.IDCoCau and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
		LEFT JOIN
					(SELECT ns.IDNhanSu, cd.IDCoCau,cd.IDChucDanh,ns.IDKhachHang, row_number() over (partition by cd.IDChucDanh order by cd.LaCapTruong desc) as STT
					FROM SYS_NhanSu ns
					INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
					WHERE ISNULL(ns.IsDelete,0)=0 and ISNULL(ns.TrangThai,0)=1
					AND ns.IDKhachHang=@IDKhachHang) ns 
					ON ns.IDCoCau=cc.IDCoCau and ns.IDChucDanh=cd.IDChucDanh and ns.IDKhachHang=cc.IDKhachHang and ns.STT=1
		INNER JOIN TW_HeThongMucTieu htmt on cc.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on cc.IDKhachHang=htmt.IDKhachHang and cc.IDCoCau=dg.IDCoCau AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS AND dg.IDNguoiPhuTrach<=0
		LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia
		WHERE htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND cc.IDCoCau in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (cc.IDCoCau in (select id from @TableID) OR ns.IDCoCau in (select id from @TableID)))
					)
				)
			)
		AND ISNULL(cc.IsDelete,0)=0
		AND ISNULL(cc.SuDung,0)=1
		and htmt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IDCoCau IS NULL OR cc.CayThuMuc like '%;' + cast(@IDCoCau as varchar(20)) + ';%')
		ORDER BY isnull(isnull(dgth.DiemDuyet,dg.TongDiem),0) desc, cc.MaThuMuc
		OFFSET (@PageIndex - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;

		SELECT tmp.*, @TotalRow as TotalRow, ISNULL(dgth.Khoa,dg.Khoa) as Khoa,dgth.MucDuyet,dgth.DiemDuyet,dgth.NhanXet,ns.MaNhanSu, ns.HoVaTen, ns.TenNhanSuNgan, ns.AnhNhanSu,cc.MaCoCau, cc.TenCoCau,cc.TenCoCauNgan,cc.CoLopCon,cc.STT,cc.CapBac,cd.MaChucDanh,cd.TenChucDanh, cd.TenChucDanhNgan,
		mdg1.MauSac as MauSac1,
		mdg2.MauSac as MauSac2
		FROM @TMP_DanhGiaTongHop tmp
		LEFT JOIN SYS_NhanSu ns on ns.IDNhanSu=tmp.IDNhanSu
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=tmp.IDCoCau
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=tmp.IDChucDanh
		LEFT JOIN TW_DanhGiaTongHop dgth on tmp.IDDanhGia=dgth.IDDanhGia
		LEFT JOIN TW_DanhGia dg on tmp.IDDanhGia=dg.IDDanhGia
		LEFT JOIN TW_MucDanhGia mdg1 on mdg1.IDKhachHang=@IDKhachHang AND ISNULL(mdg1.IsDelete,0)=0 AND UPPER(mdg1.MaMucDanhGia)=UPPER(tmp.MucDanhGia) AND mdg1.IDChuThe=0 
		LEFT JOIN TW_MucDanhGia mdg2 on mdg2.IDKhachHang=@IDKhachHang AND ISNULL(mdg2.IsDelete,0)=0 AND UPPER(mdg2.MaMucDanhGia)=UPPER(dgth.MucDuyet) AND mdg2.IDChuThe=0
		ORDER BY tmp.STT;
	END;
	ELSE
	BEGIN--Theo Nhân sự
		
		SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		IF @IDQuyen=1
		INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
		IF @IDQuyen=2 OR @IDQuyen=3
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
	
			--Them Chuc Danh kiem nhiem
			INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
			SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
			FROM SYS_NhanSu ns
			INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
			INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
			INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
			WHERE ns.IDNhanSu=@IDNhanSu;

			SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
			WHILE @cnt <= @cnt_total
			BEGIN
				SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
				IF @CayThuMuc IS NOT NULL 
					INSERT INTO @TableID (id) 
					SELECT cc.IDCoCau 
					from SYS_CoCau cc
					LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
					where cc.IDKhachHang=@IDKhachHang
					AND tmp.id is null
					and cc.CayThuMuc like @CayThuMuc+'%';
				SET @cnt = @cnt + 1;
			END;
		END;

		IF @IDQuyen=4
		BEGIN
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
		END;

		SELECT @TotalRow=COUNT(*)
		FROM SYS_NhanSu ns
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=ns.IDCoCau
		INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh
		INNER JOIN TW_HeThongMucTieu htmt on ns.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on ns.IDKhachHang=htmt.IDKhachHang and ns.IDNhanSu=dg.IDNguoiPhuTrach AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS AND dg.IDCoCau<=0
		LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia
		--Kiểm tra Quyền theo setting
		LEFT JOIN @TableID Q1 ON (@IDQuyen=5
			OR (@IDQuyen=1 AND ns.IDNhanSu=Q1.id)
			OR (@IDQuyen in (2,3,4) AND (ns.IDCoCau=Q1.id))
			)
		WHERE ns.IDKhachHang=@IDKhachHang
		AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
		and htmt.IDHTMT=@IDHTMT
		AND ISNULL(ns.IsDelete,0)=0
		AND ns.TrangThai=1
		AND (@IDCoCauPhuTrach Is null OR (@IDCoCauPhuTrach is not null and ns.IDCoCau = @IDCoCauPhuTrach))
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ns.IDNhanSu = @IDNguoiPhuTrach))

		INSERT INTO @TMP_DanhGiaTongHop (IDNhanSu,IDDanhGia,IDChucDanh,IDCoCau,MucDanhGia,Diem,DiemCongTru,TongDiem,STT)
		SELECT ns.IDNhanSu,ISNULL(dg.IDDanhGia,0),
		(CASE WHEN ISNULL(dg.IDChucDanh,0)>0 THEN dg.IDChucDanh 
			ELSE ns.IDChucDanh END
		) as IDChucDanh,
		ISNULL(ns.IDCoCau,0),dg.MaMucDanhGia,dg.Diem,dg.DiemCongTru,dg.TongDiem, row_number() over (order by isnull(isnull(dgth.DiemDuyet,dg.TongDiem),0) desc, cc.MaThuMuc) as STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=ns.IDCoCau
		INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh
		INNER JOIN TW_HeThongMucTieu htmt on ns.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on ns.IDKhachHang=htmt.IDKhachHang and ns.IDNhanSu=dg.IDNguoiPhuTrach AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS AND dg.IDCoCau<=0
		LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia
		--Kiểm tra Quyền theo setting
		LEFT JOIN @TableID Q1 ON (@IDQuyen=5
			OR (@IDQuyen=1 AND ns.IDNhanSu=Q1.id)
			OR (@IDQuyen in (2,3,4) AND (ns.IDCoCau=Q1.id))
			)
		WHERE ns.IDKhachHang=@IDKhachHang
		AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
		and htmt.IDHTMT=@IDHTMT
		AND ISNULL(ns.IsDelete,0)=0
		AND ns.TrangThai=1
		AND (@IDCoCauPhuTrach Is null OR (@IDCoCauPhuTrach is not null and ns.IDCoCau = @IDCoCauPhuTrach))
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ns.IDNhanSu = @IDNguoiPhuTrach))
		ORDER BY isnull(isnull(dgth.DiemDuyet,dg.TongDiem),0) desc, cc.MaThuMuc
		OFFSET (@PageIndex - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;

		SELECT tmp.*
		, @TotalRow as TotalRow,ISNULL(dgth.Khoa,dg.Khoa) as Khoa, dgth.MucDuyet,dgth.DiemDuyet,dgth.NhanXet,ns.MaNhanSu, ns.HoVaTen, ns.TenNhanSuNgan, ns.AnhNhanSu,cc.MaCoCau, cc.TenCoCau,cc.TenCoCauNgan,cc.CoLopCon,cc.STT,cc.CapBac,cd.MaChucDanh,cd.TenChucDanh, cd.TenChucDanhNgan,
		mdg1.MauSac as MauSac1,
		mdg2.MauSac as MauSac2
		FROM @TMP_DanhGiaTongHop tmp
		LEFT JOIN SYS_NhanSu ns on ns.IDNhanSu=tmp.IDNhanSu
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=ns.IDCoCau
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=tmp.IDChucDanh
		LEFT JOIN TW_DanhGiaTongHop dgth on tmp.IDDanhGia=dgth.IDDanhGia
		LEFT JOIN TW_DanhGia dg on tmp.IDDanhGia=dg.IDDanhGia
		LEFT JOIN TW_MucDanhGia mdg1 on mdg1.IDKhachHang=@IDKhachHang AND ISNULL(mdg1.IsDelete,0)=0 AND UPPER(mdg1.MaMucDanhGia)=UPPER(tmp.MucDanhGia) AND mdg1.IDChuThe=1 
		LEFT JOIN TW_MucDanhGia mdg2 on mdg2.IDKhachHang=@IDKhachHang AND ISNULL(mdg2.IsDelete,0)=0 AND UPPER(mdg2.MaMucDanhGia)=UPPER(dgth.MucDuyet) AND mdg2.IDChuThe=1
		ORDER BY tmp.STT;
	END;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BC_LAY_DSTopBongBong]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BC_LAY_DSTopBongBong]
@Top int=null,
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@DaDuyet bit=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	IF @Top IS NULL
	BEGIN
		SELECT @Top = 500;
	END;

	With tmp as
		(SELECT TOP (@Top) mt.IDMucTieu,mt.MaMucTieu,mt.TenMucTieu,mt.DiemHoanThanh,mt.TyLeHoanThanh,nmt.IDLoaiMucTieu,ISNULL(mt.TrongSo,0) as TrongSo
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=mt.IDHTMT AND ISNULL(nmt.IsDelete,0) = 0 AND ISNULL(nmt.SuDung,0) = 1
		INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=mt.IDHTMT AND ISNULL(lmt.IsDelete,0) = 0 AND ISNULL(lmt.SuDung,0) = 1
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
		where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		AND mt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
		AND ISNULL(mt.IsDelete,0) = 0
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (
				(ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
			)
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		ORDER BY mt.TrongSo, mt.IDMucTieu)
	SELECT * from tmp
	ORDER BY IDMucTieu;

END


GO
/****** Object:  StoredProcedure [dbo].[sp_BC_LAY_DSTopKhoi]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BC_LAY_DSTopKhoi]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@DaDuyet bit=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT TOP 6 cc.IDCoCau,cc.MaCoCau,cc.TenCoCau,dg.Diem,dg.MaMucDanhGia
	from SYS_CoCau cc 
		LEFT JOIN SYS_ChucDanh cd on cd.IDCoCau=cc.IDCoCau and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
		INNER JOIN TW_HeThongMucTieu htmt on cc.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on cc.IDKhachHang=htmt.IDKhachHang and cc.IDCoCau=dg.IDCoCau AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS
		--Kiểm tra Quyền theo setting
		LEFT JOIN @TableID Q1 ON (@IDQuyen=5
			OR (@IDQuyen in (1,2,3,4) AND (cc.IDCoCau=Q1.id))
			)
		WHERE cc.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
		AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
		AND ISNULL(cc.IsDelete,0)=0
		and htmt.IDHTMT=@IDHTMT
		AND dg.IDCoCau>0
		AND ISNULL(dg.IDNguoiPhuTrach,0)=0
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND cc.IDCoCau !=@IDCoCau
		AND cc.CayThuMuc like '%;' + cast(@IDCoCau as varchar(20)) + ';%'
		order by dg.Diem desc, cc.MaCoCau
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BC_LAY_DSTopMucTieuKem]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BC_LAY_DSTopMucTieuKem]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@DaDuyet bit=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT TOP 5 mt.IDMucTieu,mt.MaMucTieu,mt.TenMucTieu,mt.DiemHoanThanh,mt.TyLeHoanThanh
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=mt.IDHTMT AND ISNULL(nmt.IsDelete,0) = 0 AND ISNULL(nmt.SuDung,0) = 1
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=mt.IDHTMT AND ISNULL(lmt.IsDelete,0) = 0 AND ISNULL(lmt.SuDung,0) = 1
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(
					(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
					OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
				)
			)
		)
	AND mt.TyLeHoanThanh<100
	AND htmt.SuDung=1
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND ISNULL(mt.IsDelete,0) = 0
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (
			(ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	ORDER BY mt.TyLeHoanThanh asc, mt.MaMucTieu;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BC_LAY_DSTopMucTieuTot]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BC_LAY_DSTopMucTieuTot]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@DaDuyet bit=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT TOP 5 mt.IDMucTieu,mt.MaMucTieu,mt.TenMucTieu,mt.DiemHoanThanh,mt.TyLeHoanThanh
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=mt.IDHTMT AND ISNULL(nmt.IsDelete,0) = 0 AND ISNULL(nmt.SuDung,0) = 1
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=mt.IDHTMT AND ISNULL(lmt.IsDelete,0) = 0 AND ISNULL(lmt.SuDung,0) = 1
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(
					(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
					OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
				)
			)
		)
	AND mt.TyLeHoanThanh>0
	AND htmt.SuDung=1
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND ISNULL(mt.IsDelete,0) = 0
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (
			(ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	ORDER BY mt.TyLeHoanThanh desc, mt.MaMucTieu;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BC_LAY_DSTopRadar]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BC_LAY_DSTopRadar]
@TopNhom int=6,
@TopMucTieu int=5,
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@DaDuyet bit=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	DECLARE @TableNhom TABLE(id bigint NOT NULL, ThuTu bigint);
	INSERT INTO @TableNhom (id)
	SELECT distinct 
			(CASE 
			WHEN ISNULL(nmt.IDCha,0) = 0 THEN nmt.IDNhomMucTieu
			ELSE nmt.IDCha
			END) as IDNhomMucTieu
	FROM TW_MucTieu mt
		INNER JOIN TW_NhomMucTieu nmt on nmt.IDHTMT=mt.IDHTMT and nmt.IDNhomMucTieu=mt.IDNhomMucTieu
		INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=mt.IDHTMT AND ISNULL(lmt.IsDelete,0) = 0 AND ISNULL(lmt.SuDung,0) = 1
		INNER JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
		WHERE mt.IDHTMT=@IDHTMT
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
		AND ISNULL(mt.IsDelete,0) = 0
		AND ISNULL(nmt.IsDelete,0) = 0
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (
				(ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
			)
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu));
	
	UPDATE @TableNhom 
		SET ThuTu=STT
		FROM (SELECT IDNhomMucTieu, ThuTu as STT
			FROM TW_NhomMucTieu) AS OtherTable
		WHERE ID=OtherTable.IDNhomMucTieu;;

	SELECT tmp.*, nmt.MaNhomMucTieu,nmt.TenNhomMucTieu
	FROM
	(
		SELECT (CASE 
			WHEN ISNULL(nmt.IDCha,0) = 0 THEN nmt.IDNhomMucTieu
			ELSE nmt.IDCha
			END) as IDNhomMucTieu,
		mt.IDMucTieu,
		SUBSTRING(mt.MaMucTieu, 0, 5)  as MaMucTieu
		--mt.MaMucTieu
		,dvt.IDKieuDuLieu,nmt.ThuTu,
		ROUND(mt.TyLeHoanThanh,2) as TyLeHoanThanh,
		row_number() over (partition by (CASE 
											WHEN ISNULL(nmt.IDCha,0) = 0 THEN nmt.IDNhomMucTieu
											ELSE nmt.IDCha
											END) 
											order by ISNULL(mt.TyLeHoanThanh,0) desc) as STT 
		FROM TW_MucTieu mt
		INNER JOIN TW_NhomMucTieu nmt on nmt.IDHTMT=mt.IDHTMT and nmt.IDNhomMucTieu=mt.IDNhomMucTieu
		INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=mt.IDHTMT AND ISNULL(lmt.IsDelete,0) = 0 AND ISNULL(lmt.SuDung,0) = 1
		INNER JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
		WHERE mt.IDHTMT=@IDHTMT
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
		AND ISNULL(mt.IsDelete,0) = 0
		AND ISNULL(nmt.IsDelete,0) = 0
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (
				(ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
			)
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		AND (mt.IDNhomMucTieu in (SELECT TOP (@TopNhom) id FROM @TableNhom ORDER BY ThuTu) OR nmt.IDCha in (SELECT TOP (@TopNhom) id FROM @TableNhom ORDER BY ThuTu))
	) tmp
	INNER JOIN TW_NhomMucTieu nmt ON nmt.IDNhomMucTieu=tmp.IDNhomMucTieu
	WHERE STT<=@TopMucTieu
	ORDER BY ThuTu, STT;
END



GO
/****** Object:  StoredProcedure [dbo].[sp_BC_LAY_ThongKeMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BC_LAY_ThongKeMucTieu]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@DaDuyet bit=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @CountDaKetThuc int, @CountDangLam int, @CountChuaLam int;

	--Đã kết thúc----------------------------------------------
	SELECT @CountDaKetThuc = COUNT(*)
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=mt.IDHTMT AND ISNULL(nmt.IsDelete,0) = 0 AND ISNULL(nmt.SuDung,0) = 1
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=mt.IDHTMT AND ISNULL(lmt.IsDelete,0) = 0 AND ISNULL(lmt.SuDung,0) = 1
	INNER JOIN TW_DanhGia dg on dg.IDHTMT=mt.IDHTMT and dg.IDHTTS=@IDHTTS
		AND (
			(ISNULL(@ChuThe,0) = 0 AND ISNULL(dg.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(dg.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(dg.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	where htmt.IDKhachHang=@IDKhachHang
	AND htmt.SuDung=1
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND ISNULL(mt.IsDelete,0) = 0
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (
			(ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND mt.IDTrangThaiMucTieu=3;--Kết thúc

	--Đang làm----------------------------------------------
	SELECT @CountDangLam = COUNT(*)
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=mt.IDHTMT AND ISNULL(nmt.IsDelete,0) = 0 AND ISNULL(nmt.SuDung,0) = 1
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=mt.IDHTMT AND ISNULL(lmt.IsDelete,0) = 0 AND ISNULL(lmt.SuDung,0) = 1
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	where htmt.IDKhachHang=@IDKhachHang
	AND htmt.SuDung=1
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND ISNULL(mt.IsDelete,0) = 0
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (
			(ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND mt.IDTrangThaiMucTieu=2;--Đang làm

	--Chưa làm----------------------------------------------
	SELECT @CountChuaLam = COUNT(*)
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=mt.IDHTMT AND ISNULL(nmt.IsDelete,0) = 0 AND ISNULL(nmt.SuDung,0) = 1
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=mt.IDHTMT AND ISNULL(lmt.IsDelete,0) = 0 AND ISNULL(lmt.SuDung,0) = 1
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	where htmt.IDKhachHang=@IDKhachHang
	AND htmt.SuDung=1
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	--AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND ISNULL(mt.IsDelete,0) = 0
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (
			(ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND ISNULL(mt.IDTrangThaiMucTieu,0) in (0,1);--Chưa làm

	SELECT 
		@CountDaKetThuc as val1, 
		@CountDangLam as val2,
		@CountChuaLam as val3,
		0 as val4,
		0 as val5;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BI_301]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BI_301]
@IDHTMT	bigint =null,-- 25,
@IDLoaiTanSuat tinyint=null,--3,
@IDCoCau bigint=null,--386,
@IDMucTieu bigint=null,--924658,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT TOP 20 mt.IDMucTieu,mt.IDMucTieuCha,htts.IDLoaiTanSuat,mt.MaThuMuc,mt.CayThuMuc,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu as nvarchar(50))+'%'
	ORDER BY htts.BatDau,htts.TenTanSuat
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BI_302]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BI_302]
@IDHTMT	bigint =null,-- 25,
@IDLoaiTanSuat tinyint=null,--3,
@IDCoCau bigint=null,--386,
@IDMucTieu bigint=null,--924658,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT TOP 20 mt.IDMucTieu,mt.IDMucTieuCha,htts.IDLoaiTanSuat,mt.MaThuMuc,mt.CayThuMuc,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu as nvarchar(50))+'%'
	ORDER BY htts.BatDau,htts.TenTanSuat
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BI_303]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BI_303]
@IDHTMT	bigint =null,-- 25,
@IDLoaiTanSuat tinyint=null,--3,
@IDCoCau bigint=null,--386,
@IDMucTieu bigint=null,--924658,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT TOP 20 mt.IDMucTieu,mt.IDMucTieuCha,htts.IDLoaiTanSuat,mt.MaThuMuc,mt.CayThuMuc,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu as nvarchar(50))+'%'
	ORDER BY htts.BatDau,htts.TenTanSuat
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BI_304]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BI_304]
@IDHTMT	bigint =null,-- 25,
@IDLoaiTanSuat tinyint=null,--3,
@IDCoCau bigint=null,--386,
@IDMucTieu bigint=null,--924658,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT TOP 20 mt.IDMucTieu,mt.IDMucTieuCha,htts.IDLoaiTanSuat,mt.MaThuMuc,mt.CayThuMuc,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu as nvarchar(50))+'%'
	ORDER BY htts.BatDau,htts.TenTanSuat
END


GO
/****** Object:  StoredProcedure [dbo].[sp_BI_305]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BI_305]
@IDHTMT1 bigint =null,-- 25,
@IDHTMT2 bigint =null,-- 25,
@IDLoaiTanSuat1 tinyint=null,--3,
@IDLoaiTanSuat2 tinyint=null,--3,
@IDCoCau1 bigint=null,--386,
@IDCoCau2 bigint=null,--386,
@IDMucTieu1 bigint=null,--924658,
@IDMucTieu2 bigint=null,--924658,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	With tmp as
	(
	SELECT TOP 20 mt.IDMucTieu,htts.BatDau,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT,
	1 as Loai
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT1
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau1
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat1
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu1
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu1 as nvarchar(50))+'%'
	UNION
	SELECT TOP 20 mt.IDMucTieu,htts.BatDau,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT,
	2 as Loai
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT2
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau2
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat2
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu2
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu2 as nvarchar(50))+'%'
	)
	SELECT * FROM tmp
	ORDER BY Loai,BatDau,TenTanSuat
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BI_306]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BI_306]
@IDHTMT1 bigint =null,-- 25,
@IDHTMT2 bigint =null,-- 25,
@IDLoaiTanSuat1 tinyint=null,--3,
@IDLoaiTanSuat2 tinyint=null,--3,
@IDCoCau1 bigint=null,--386,
@IDCoCau2 bigint=null,--386,
@IDMucTieu1 bigint=null,--924658,
@IDMucTieu2 bigint=null,--924658,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	With tmp as
	(
	SELECT TOP 20 mt.IDMucTieu,htts.BatDau,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT,
	1 as Loai
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT1
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau1
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat1
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu1
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu1 as nvarchar(50))+'%'
	UNION
	SELECT TOP 20 mt.IDMucTieu,htts.BatDau,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT,
	2 as Loai
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT2
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau2
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat2
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu2
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu2 as nvarchar(50))+'%'
	)
	SELECT * FROM tmp
	ORDER BY Loai,BatDau,TenTanSuat
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BI_307]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BI_307]
@IDHTMT1 bigint =null,-- 25,
@IDHTMT2 bigint =null,-- 25,
@IDLoaiTanSuat1 tinyint=null,--3,
@IDLoaiTanSuat2 tinyint=null,--3,
@IDCoCau1 bigint=null,--386,
@IDCoCau2 bigint=null,--386,
@IDMucTieu1 bigint=null,--924658,
@IDMucTieu2 bigint=null,--924658,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	With tmp as
	(
	SELECT TOP 20 mt.IDMucTieu,htts.BatDau,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT,
	1 as Loai
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT1
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau1
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat1
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu1
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu1 as nvarchar(50))+'%'
	UNION
	SELECT TOP 20 mt.IDMucTieu,htts.BatDau,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT,
	2 as Loai
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT2
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau2
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat2
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu2
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu2 as nvarchar(50))+'%'
	)
	SELECT * FROM tmp
	ORDER BY Loai,BatDau,TenTanSuat
END
GO
/****** Object:  StoredProcedure [dbo].[sp_BI_308]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_BI_308]
@IDHTMT1 bigint =null,-- 25,
@IDHTMT2 bigint =null,-- 25,
@IDLoaiTanSuat1 tinyint=null,--3,
@IDLoaiTanSuat2 tinyint=null,--3,
@IDCoCau1 bigint=null,--386,
@IDCoCau2 bigint=null,--386,
@IDMucTieu1 bigint=null,--924658,
@IDMucTieu2 bigint=null,--924658,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	With tmp as
	(
	SELECT TOP 20 mt.IDMucTieu,htts.BatDau,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT,
	1 as Loai
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT1
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau1
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat1
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu1
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu1 as nvarchar(50))+'%'
	UNION
	SELECT TOP 20 mt.IDMucTieu,htts.BatDau,
	htmt.MaHTMT,htts.TenTanSuat,mt.MaMucTieu, mt.TenMucTieu,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	cc.TenCoCau,npt.MaNhanSu,npt.AnhNhanSu,npt.HoVaTen,cd.TenChucDanh,ccpt.TenCoCau as TenCoCauPT,
	2 as Loai
	FROM TW_MucTieu mt 
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE cc.IDKhachHang=@IDKhachHang
	AND mt.IDHTMT=@IDHTMT2
	AND ISNULL(mt.IsDelete,0)=0
	AND mt.IDCoCau=@IDCoCau2
	AND htts.IDLoaiTanSuat=@IDLoaiTanSuat2
	--AND mt.TenMucTieu like N'%Doanh thu hợp nhất%' AND dvt.TenDonViTinh =N'Tỷ đồng'
	AND mt.IDMucTieu!=@IDMucTieu2
	AND mt.CayThuMuc like '%'+CAST(@IDMucTieu2 as nvarchar(50))+'%'
	)
	SELECT * FROM tmp
	ORDER BY Loai,BatDau,TenTanSuat
END
GO
/****** Object:  StoredProcedure [dbo].[sp_CRM_Customer_TinhTong]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_CRM_Customer_TinhTong]
@IDHTTS bigint,
@groupBy tinyint
AS
BEGIN
	INSERT INTO CRM_CTL_Customer
		(IDHTTS,agencyCode,salesmanEmail,groupBy,statusName,totalCustomer)
		(SELECT IDHTTS,agencyCode,salesmanEmail,groupBy,'[@sum]',sum(totalCustomer)
		FROM CRM_CTL_Customer
		WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND statusName!='[@sum]'
		AND groupBy!=3
		GROUP BY  IDHTTS,agencyCode,salesmanEmail,groupBy);
	
	INSERT INTO CRM_CTL_Customer
		(IDHTTS,agencyCode,salesmanEmail,groupBy,statusName,totalCustomer)
		(SELECT IDHTTS,'[@sum]',salesmanEmail,groupBy,'[@sum]',sum(totalCustomer)
		FROM CRM_CTL_Customer
		WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND statusName!='[@sum]'
		AND groupBy=3
		GROUP BY  IDHTTS,salesmanEmail,groupBy);

	DELETE FROM CRM_CTL_Customer WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND statusName!='[@sum]';
END
GO
/****** Object:  StoredProcedure [dbo].[sp_CRM_Customer_TuongTac_TinhTong]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_CRM_Customer_TuongTac_TinhTong]
@IDHTTS bigint,
@groupBy tinyint
AS
BEGIN
	INSERT INTO CRM_CTL_Customer_TuongTac
		(IDHTTS,agencyCode,salesmanEmail,groupBy,statusName,totalCustomer)
		(SELECT IDHTTS,agencyCode,salesmanEmail,groupBy,'[@sum]',sum(totalCustomer)
		FROM CRM_CTL_Customer_TuongTac
		WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND statusName!='[@sum]'
		AND groupBy!=3
		GROUP BY  IDHTTS,agencyCode,salesmanEmail,groupBy);
	
	INSERT INTO CRM_CTL_Customer_TuongTac
		(IDHTTS,agencyCode,salesmanEmail,groupBy,statusName,totalCustomer)
		(SELECT IDHTTS,'[@sum]',salesmanEmail,groupBy,'[@sum]',sum(totalCustomer)
		FROM CRM_CTL_Customer_TuongTac
		WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND statusName!='[@sum]'
		AND groupBy=3
		GROUP BY  IDHTTS,salesmanEmail,groupBy);

	DELETE FROM CRM_CTL_Customer_TuongTac WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND statusName!='[@sum]';
END
GO
/****** Object:  StoredProcedure [dbo].[sp_CRM_Revenue_TinhTong]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_CRM_Revenue_TinhTong]
@IDHTTS bigint,
@groupBy tinyint
AS
BEGIN
	INSERT INTO CRM_CTL_Revenue 
		(IDHTTS,projectCode,propertyType,agencyCode,salesmanEmail,groupBy,totalRevenue)
		(SELECT IDHTTS,'[@sum]','[@sum]',agencyCode,salesmanEmail,groupBy,sum(totalRevenue)
		FROM CRM_CTL_Revenue
		WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND projectCode!='[@sum]' AND propertyType!='[@sum]'
		AND groupBy!=3
		GROUP BY IDHTTS,agencyCode,salesmanEmail,groupBy);
	
	INSERT INTO CRM_CTL_Revenue 
		(IDHTTS,projectCode,propertyType,agencyCode,salesmanEmail,groupBy,totalRevenue)
		(SELECT IDHTTS,'[@sum]','[@sum]','[@sum]',salesmanEmail,groupBy,sum(totalRevenue)
		FROM CRM_CTL_Revenue
		WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND projectCode!='[@sum]' AND propertyType!='[@sum]'
		AND groupBy=3
		GROUP BY IDHTTS,salesmanEmail,groupBy);

	DELETE FROM CRM_CTL_Revenue WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND projectCode!='[@sum]' AND propertyType!='[@sum]'
END
GO
/****** Object:  StoredProcedure [dbo].[sp_CRM_Sale_TinhTong]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_CRM_Sale_TinhTong]
@IDHTTS bigint,
@groupBy tinyint
AS
BEGIN
	INSERT INTO CRM_CTL_Sale 
		(IDHTTS,projectCode,propertyType,agencyCode,salesmanEmail,groupBy,totalSales)
		(SELECT IDHTTS,'[@sum]','[@sum]',agencyCode,salesmanEmail,groupBy,sum(totalSales)
		FROM CRM_CTL_Sale
		WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND projectCode!='[@sum]' AND propertyType!='[@sum]'
		AND groupBy!=3
		GROUP BY IDHTTS,agencyCode,salesmanEmail,groupBy);
	
	INSERT INTO CRM_CTL_Sale 
		(IDHTTS,projectCode,propertyType,agencyCode,salesmanEmail,groupBy,totalSales)
		(SELECT IDHTTS,'[@sum]','[@sum]','[@sum]',salesmanEmail,groupBy,sum(totalSales)
		FROM CRM_CTL_Sale
		WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND projectCode!='[@sum]' AND propertyType!='[@sum]'
		AND groupBy=3
		GROUP BY IDHTTS,salesmanEmail,groupBy);

	DELETE FROM CRM_CTL_Sale WHERE IDHTTS=@IDHTTS AND groupBy=@groupBy AND projectCode!='[@sum]' AND propertyType!='[@sum]'
END
GO
/****** Object:  StoredProcedure [dbo].[sp_DanhGia_LAY_DSMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_DanhGia_LAY_DSMucTieu]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IsDanhGia tinyint,
@IDCoCau bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@IsOverWrite bit=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	IF @IDCoCau=0
	BEGIN
		SELECT @ChuThe=1;
		SELECT @IDCoCau=null;
	END;
	ELSE
	BEGIN
		--Xoa Ket qua Danh gia cua NhanSu khac dam nhiem bo phan
		DECLARE @IDNhanSuChinh bigint;
		SELECT @IDNhanSuChinh=ns.IDNhanSu
		FROM SYS_NhanSu ns
		INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
		WHERE ISNULL(ns.IsDelete,0)=0 and ISNULL(ns.TrangThai,0)=1
		AND ns.IDKhachHang=@IDKhachHang
		AND ns.IDCoCau=@IDCoCau 
		and ns.IDKhachHang=@IDKhachHang

		IF ISNULL(@IDNhanSuChinh,0)>0
		BEGIN
			DELETE FROM TW_DanhGia
			WHERE IDHTMT=@IDHTMT and IDHTTS=@IDHTTS AND IDCoCau=@IDCoCau AND IDNguoiPhuTrach>0 AND IDNguoiPhuTrach!=@IDNhanSuChinh;
		END;
	END;

	DECLARE @TableIDMucTieu TABLE(IDMucTieu bigint NOT NULL, MucTieuGoc int);
	
	DECLARE @IDDanhGia bigint;
	SELECT @IDDanhGia=IDDanhGia FROM TW_DanhGia WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0);

	DECLARE @CountKN int=0;
	IF ISNULL(@ChuThe,0) = 1
	BEGIN
		SELECT @CountKN=COUNT(*) 
		FROM TW_TyTrongChucDanh ttcd
		LEFT JOIN SYS_NhanSu ns on ns.IDChucDanh=ttcd.IDChucDanh and ns.IDNhanSu=ttcd.IDNhanSu
		WHERE ttcd.IDHTMT=@IDHTMT 
			and ttcd.IDHTTS=@IDHTTS 
			and ttcd.IDNhanSu=@IDNguoiPhuTrach 
			and ISNULL(ttcd.TyTrong,0)>0
			AND ns.IDNhanSu is null;--Không phải chức danh chính

		--Xoa bớt dánh giá kiêm nhiệm
		DELETE FROM TW_DanhGia 
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) 
		and IDChucDanh>0
		and (@CountKN=0
			 OR IDChucDanh IN (SELECT IDChucDanh FROM TW_TyTrongChucDanh  
							  WHERE IDHTMT=@IDHTMT 
							  and IDHTTS=@IDHTTS 
							  and IDNhanSu=@IDNguoiPhuTrach 
							  and ISNULL(TyTrong,0)=0--Chức danh tỷ trọng = 0 => không kiêm nhiệm
							)
			)
	END;

	--Xoa kết quả đánh giá cũ
	IF @IsDanhGia=1
	BEGIN
		UPDATE TW_DanhGia
		SET Diem=null, MaMucDanhGia=null,LastUpdatedDate=getdate(),LastUpdatedBy=@IDNhanSu
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0);

		UPDATE TW_MucTieuTrongSo
		SET TrongSoPT=null
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0);
	END;
	ELSE
	BEGIN
		UPDATE TW_DanhGia
		SET DiemTamTinh=null, MaMucTamTinh=null,LastUpdatedDate=getdate(),LastUpdatedBy=@IDNhanSu
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0);

		UPDATE TW_MucTieuTrongSo
		SET TrongSoPTTamTinh=null
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0);
	END;
	
	IF @IsDanhGia=1
	BEGIN
		UPDATE TW_NhomMucTieuKetQua
		SET DiemHoanThanh=null,
			TyLeHoanThanh=null
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS
			AND (
					(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
					OR 
					(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
				);
	END;
	ELSE
	BEGIN
		UPDATE TW_NhomMucTieuKetQua
		SET DiemTamTinh=null,
			TyLeTamTinh=null
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS
			AND (
					(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
					OR 
					(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
				);
	END;
	IF @IsDanhGia=1
	BEGIN
		UPDATE TW_LoaiMucTieuKetQua
		SET DiemHoanThanh=null,TyLeHoanThanh=null
		WHERE IDDanhGia=@IDDanhGia;
	END;
	ELSE
	BEGIN
		UPDATE TW_LoaiMucTieuKetQua
		SET DiemTamTinh=null,TyLeTamTinh=null
		WHERE IDDanhGia=@IDDanhGia;
	END;
	
	--Xóa kết quả đánh giá của chỉ tiêu
	IF @IsDanhGia=1
	BEGIN
		UPDATE TW_MucTieu
		SET TyLeHoanThanh=null,
			DiemHoanThanh=null
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS
		AND DiemHoanThanh is not null
		AND (
				(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
			)
	END;
	ELSE
	BEGIN
		UPDATE TW_MucTieu
		SET TyLeTamTinh=null,
			DiemTamTinh=null
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS
		AND DiemHoanThanh is not null
		AND (
				(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
			)
	END;

	--Sua Trang Thai Muc Tieu Mới thành đang làm
	UPDATE TW_MucTieu
	SET IDTrangThaiMucTieu=2
	WHERE IDHTMT=@IDHTMT
	AND IDHTTS = @IDHTTS
	AND IDHTMT=@IDHTMT
	AND ISNULL(IDTrangThaiMucTieu,1)=1
	AND ISNULL(IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND ISNULL(IsDelete,0) = 0
	AND (
			(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)));

	--Lấy danh sách mục tiêu GỐC
	INSERT INTO @TableIDMucTieu (IDMucTieu, MucTieuGoc)
	SELECT mt.IDMucTieu, 1
	FROM TW_MucTieu mt
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDHTMT=mt.IDHTMT and lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu
	WHERE mt.IDHTMT=@IDHTMT
	AND mt.IDHTTS = @IDHTTS
	AND mt.IDHTMT=@IDHTMT
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND (
			(mt.CTSoThucTe is not null)
			OR 
			(@IsDanhGia=0 OR ISNULL(nkq.IDTrangThaiDuyet,0) in (4,7,10))--Duyệt cấp 1,2,3
		)
	AND ISNULL(mt.IsDelete,0) = 0
	AND (
			(ISNULL(@ChuThe,0) = 0 AND mt.IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)));

	--Lấy danh sách mục tiêu theo CÔNG THỨC CTSoThucTe
	INSERT INTO @TableIDMucTieu  (IDMucTieu, MucTieuGoc)
	SELECT DISTINCT ytt.IDMucTieuTinh, 0
	FROM TW_YeuToTinhSoThucTe ytt
	WHERE ytt.IDMucTieu in (select IDMucTieu from @TableIDMucTieu)
	AND ytt.IDMucTieuTinh not in (select IDMucTieu from @TableIDMucTieu)

	--Nếu @CountKN>0 => có kiêm nhiệm
	--Lấy danh sách mục tiêu để đánh giá
	SELECT nmt.IDNhomMucTieu,nmt.MaNhomMucTieu,
	case 
		when ISNULL(@ChuThe,0) = 1 AND @CountKN>0 and ttcd.IDChucDanh is not null and ISNULL(ttcd.IsKiemNhiem,0)=1 then mt.IDChucDanh--Chức danh kiêm nhiệm
		when ISNULL(@ChuThe,0) = 1 AND @CountKN>0 and ttcd.IDChucDanh is not null and ISNULL(ttcd.IsKiemNhiem,0)=0 then ns.IDChucDanh--Đổi các chức danh ko có trong kiêm nhiệm về chức danh chính
		else 0--Đánh giá chủ thể bộ phận
	end as IDChucDanh,
	mt.IDMucTieu,ISNULL(mt.IDMucTieuCha,0) as IDMucTieuCha,mt.MaMucTieu, dvt.IDKieuDuLieu, 
	(CASE 
		WHEN lower(mt.CTSoThucTe) in (lower('DoanhSo'),lower('DoanhThu'),lower('KhachHangMoi'),lower('KhachHangTuongTac')) then null
		ELSE mt.CTSoThucTe
	END) as CTSoThucTe,
	--mt.CTSoThucTe,
	mt.SoKeHoachSo,mt.SoKeHoachNgay,
	mt.SoKeHoachTyLe,mt.DaDanhGia,mt.TrongSo,tmp.MucTieuGoc,
	(CASE 
		WHEN dvt.IDKieuDuLieu=1 and lower(mt.CTSoThucTe) = lower('DoanhSo') then DSo.totalSales
		WHEN dvt.IDKieuDuLieu=1 and lower(mt.CTSoThucTe) = lower('DoanhThu') then DThu.totalRevenue
		WHEN dvt.IDKieuDuLieu=1 and lower(mt.CTSoThucTe) = lower('KhachHangMoi') then KHang.totalCustomer
		WHEN dvt.IDKieuDuLieu=1 and lower(mt.CTSoThucTe) = lower('KhachHangTuongTac') then KHangTT.totalCustomer
		ELSE ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo)))
	END) as SoThucTeSo,
	--ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	(CASE 
		WHEN dvt.IDKieuDuLieu=3 and lower(mt.CTSoThucTe) = lower('DoanhSo') then DSo.totalSales
		WHEN dvt.IDKieuDuLieu=3 and lower(mt.CTSoThucTe) = lower('DoanhThu') then DThu.totalRevenue
		WHEN dvt.IDKieuDuLieu=3 and lower(mt.CTSoThucTe) = lower('KhachHangMoi') then KHang.totalCustomer
		WHEN dvt.IDKieuDuLieu=3 and lower(mt.CTSoThucTe) = lower('KhachHangTuongTac') then KHangTT.totalCustomer
		ELSE ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe)))
	END) as SoThucTeTyLe,
	--ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	ISNULL(lmt.TinhTrucTiep,0) as TinhTrucTiep,
	case 
		when CTSoThucTe is null and dvt.IDKieuDuLieu=1 and nkq.SoThucTeSo3 is null and nkq.SoThucTeSo2 is null and nkq.SoThucTeSo1 is null and nkq.SoThucTeSo is null then '0'
		when CTSoThucTe is null and dvt.IDKieuDuLieu=2 and nkq.SoThucTeNgay3 is null and nkq.SoThucTeNgay2 is null and nkq.SoThucTeNgay1 is null and nkq.SoThucTeNgay is null then '0'
		when CTSoThucTe is null and dvt.IDKieuDuLieu=3 and nkq.SoThucTeTyLe3 is null and nkq.SoThucTeTyLe2 is null and nkq.SoThucTeTyLe1 is null and nkq.SoThucTeTyLe is null then '0'
		else mt.CTDiemChiTieu
	end as CTDiemChiTieu,
	lmt.TenLoaiMucTieu as TenNhom,
	lmt.TrongSo as TrongSoNhom,
	nmt.CayThuMuc
	FROM TW_MucTieu mt
	INNER JOIN @TableIDMucTieu tmp on tmp.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDHTMT=mt.IDHTMT and lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN TW_TyTrongChucDanh ttcd on ttcd.IDHTMT=@IDHTMT and ttcd.IDHTTS=@IDHTTS and ttcd.IDChucDanh=mt.IDChucDanh and ttcd.IDNhanSu=mt.IDNguoiPhuTrach and ISNULL(ttcd.TyTrong,0)>0
	LEFT JOIN CRM_CTL_Sale DSo on DSo.IDHTTS=mt.IDHTTS and lower(mt.CTSoThucTe) = lower('DoanhSo') and 
		(
		 (mt.IDCoCau=0 and Dso.groupBy=3 and lower(npt.DB_UserName)=lower(DSo.salesmanEmail))
		 OR
		 (mt.IDCoCau>0 and Dso.groupBy in (1,2) and lower(ISNULL(cc.MaTichHop,cc.MaCoCau))=lower(DSo.agencyCode))
		)
	LEFT JOIN CRM_CTL_Revenue DThu on DThu.IDHTTS=mt.IDHTTS and lower(mt.CTSoThucTe) = lower('DoanhThu') and 
		(
		 (mt.IDCoCau=0 and DThu.groupBy=3 and lower(npt.DB_UserName)=lower(DThu.salesmanEmail))
		 OR
		 (mt.IDCoCau>0 AND mt.IDCoCau>0 and DThu.groupBy in (1,2) and lower(ISNULL(cc.MaTichHop,cc.MaCoCau))=lower(DThu.agencyCode))
		)
	LEFT JOIN CRM_CTL_Customer KHang on KHang.IDHTTS=mt.IDHTTS and lower(mt.CTSoThucTe) = lower('KhachHangMoi') and 
		(
		 (mt.IDCoCau=0 and KHang.groupBy=3 and lower(npt.DB_UserName)=lower(KHang.salesmanEmail))
		 OR
		 (mt.IDCoCau>0 AND mt.IDCoCau>0 and KHang.groupBy in (1,2) and lower(ISNULL(cc.MaTichHop,cc.MaCoCau))=lower(KHang.agencyCode))
		)
	LEFT JOIN CRM_CTL_Customer_TuongTac KHangTT on KHangTT.IDHTTS=mt.IDHTTS and lower(mt.CTSoThucTe) = lower('KhachHangTuongTac') and 
		(
		 (mt.IDCoCau=0 and KHangTT.groupBy=3 and lower(npt.DB_UserName)=lower(KHangTT.salesmanEmail))
		 OR
		 (mt.IDCoCau>0 AND mt.IDCoCau>0 and KHangTT.groupBy in (1,2) and lower(ISNULL(cc.MaTichHop,cc.MaCoCau))=lower(KHangTT.agencyCode))
		)
	ORDER BY mt.IDMucTieu;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_DanhGia_LAY_DSMucTieuCTSoThucTe]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_DanhGia_LAY_DSMucTieuCTSoThucTe]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IsDanhGia tinyint,
@IDCoCau bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@IsOverWrite bit=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	--Lấy danh sách mục tiêu GỐC
	SELECT ytt.*
	FROM TW_MucTieu mt
	INNER JOIN TW_YeuToTinhSoThucTe ytt on ytt.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDHTMT=mt.IDHTMT and lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu
	WHERE mt.IDHTMT=@IDHTMT
	AND mt.IDHTTS = @IDHTTS
	AND mt.IDHTMT=@IDHTMT
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND (
			(mt.CTSoThucTe is not null)
			OR 
			(ISNULL(nkq.IDTrangThaiDuyet,0) in (4,7,10))--Duyệt cấp 1,2,3
		)
	AND ISNULL(mt.IsDelete,0) = 0
	AND (
			(ISNULL(@ChuThe,0) = 0 AND mt.IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)));
END


GO
/****** Object:  StoredProcedure [dbo].[sp_DanhGia_LAY_DSNhomMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_DanhGia_LAY_DSNhomMucTieu]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@IDCoCau bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@IsOverWrite bit=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int=1
AS
BEGIN
	RETURN;
	
	--SELECT nmt.IDNhomMucTieu,nmt.MaNhomMucTieu, nmtts.TrongSoNam,nmtts.TrongSoNuaNam,nmtts.TrongSoQuy,nmtts.TrongSoThang
	--FROM TW_NhomMucTieu nmt
	--INNER JOIN TW_NhomMucTieuTrongSo nmtts on nmtts.IDHTMT=@IDHTMT and nmtts.IDNhomMucTieu=nmt.IDNhomMucTieu
	--WHERE nmt.IDHTMT=@IDHTMT
	--AND (@IDCoCau Is null OR (@IDCoCau is not null and nmtts.IDCoCau = @IDCoCau))
	--AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and nmtts.IDNguoiPhuTrach = @IDNguoiPhuTrach))

END


GO
/****** Object:  StoredProcedure [dbo].[sp_DanhGia_SUA_MucTieuKetQua]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_DanhGia_SUA_MucTieuKetQua]
@IDHTMT	bigint = null,
@IDMucTieu bigint = null,
@IDHTTS bigint,
@IDCoCau bigint,
@IDNguoiPhuTrach bigint,
@IDChucDanh bigint,
@IsDanhGia tinyint,
@TyLeHoanThanh decimal(9, 2),
@DiemHoanThanh decimal(15, 5),
@TrongSoPT	decimal(9, 5),
@IDNhanSu bigint
AS
BEGIN
	DECLARE @Date datetime=getdate();
	DECLARE @ChuThe tinyint;
	DECLARE @Count int;
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (ISNULL(@IDCoCau,0)=0 AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
		SELECT @IDCoCau=0;
	END;

	SELECT @Count=COUNT(*) 
	FROM TW_MucTieuTrongSo
	WHERE IDHTMT=@IDHTMT AND IDMucTieu=@IDMucTieu and IDHTTS=@IDHTTS AND IDChucDanh=@IDChucDanh
	AND (
			(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)

	IF ISNULL(@IsDanhGia,0)=0
	BEGIN
		IF @Count=0
		BEGIN
			INSERT INTO TW_MucTieuTrongSo
			(IDHTMT,IDHTTS,IDMucTieu,IDCoCau,IDNguoiPhuTrach,TrongSoPT,DaDuyet,LastUpdatedDate,LastUpdatedBy,TrongSoPTTamTinh,IDChucDanh)
			VALUES 
			(@IDHTMT,@IDHTTS,@IDMucTieu,@IDCoCau,@IDNguoiPhuTrach,null,0,@Date,@IDNhanSu,@TrongSoPT,@IDChucDanh);
		END
		ELSE
		BEGIN
			UPDATE TW_MucTieuTrongSo
			SET TrongSoPTTamTinh=@TrongSoPT
			WHERE IDHTMT=@IDHTMT AND IDMucTieu=@IDMucTieu and IDHTTS=@IDHTTS AND IDChucDanh=@IDChucDanh
			AND (
					(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
					OR 
					(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
				)
		END
		UPDATE TW_MucTieu
		SET TyLeTamTinh=@TyLeHoanThanh,
			DiemTamTinh=@DiemHoanThanh,
			IDChucDanhDG=@IDChucDanh
		WHERE IDMucTieu=@IDMucTieu;
	END
	ELSE
	BEGIN
		IF @Count=0
		BEGIN
			INSERT INTO TW_MucTieuTrongSo
			(IDHTMT,IDHTTS,IDMucTieu,IDCoCau,IDNguoiPhuTrach,TrongSoPT,DaDuyet,LastUpdatedDate,LastUpdatedBy,TrongSoPTTamTinh,IDChucDanh)
			VALUES 
			(@IDHTMT,@IDHTTS,@IDMucTieu,@IDCoCau,@IDNguoiPhuTrach,@TrongSoPT,0,@Date,@IDNhanSu,null,@IDChucDanh);
		END
		ELSE
		BEGIN
			UPDATE TW_MucTieuTrongSo
			SET TrongSoPT=@TrongSoPT
			WHERE IDHTMT=@IDHTMT AND IDMucTieu=@IDMucTieu and IDHTTS=@IDHTTS AND IDChucDanh=@IDChucDanh
			AND (
					(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
					OR 
					(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
				)
			END

		UPDATE TW_MucTieu
		SET TyLeHoanThanh=@TyLeHoanThanh,
			DiemHoanThanh=@DiemHoanThanh,
			IDChucDanhDG=@IDChucDanh
		WHERE IDMucTieu=@IDMucTieu;
	END
END


GO
/****** Object:  StoredProcedure [dbo].[sp_DanhGia_SUA_NhomMucTieuKetQua]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_DanhGia_SUA_NhomMucTieuKetQua]
@IDHTMT bigint,
@IDNhomMucTieu bigint,
@IDHTTS bigint,
@IDCoCau bigint,
@IDNguoiPhuTrach bigint,
@IDChucDanh bigint,
@IsDanhGia tinyint,
@TyLeHoanThanh decimal(9, 2),
@DiemHoanThanh decimal(15, 5),
@IDNhanSu bigint
AS
BEGIN
	DECLARE @Count int=0;
	SELECT @Count=COUNT(*) 
	FROM TW_NhomMucTieuKetQua
	WHERE IDHTMT=@IDHTMT AND IDNhomMucTieu=@IDNhomMucTieu and IDHTTS=@IDHTTS and IDCoCau=ISNULL(@IDCoCau,0) and IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and IDChucDanh=ISNULL(@IDChucDanh,0);

	if @Count>0
	BEGIN
		IF @IsDanhGia=1
		BEGIN
			UPDATE TW_NhomMucTieuKetQua
			SET DiemHoanThanh=@DiemHoanThanh,
				TyLeHoanThanh=@TyLeHoanThanh,
				LastUpdatedDate=getdate(),
				LastUpdatedBy=@IDNhanSu
			WHERE IDHTMT=@IDHTMT AND IDNhomMucTieu=@IDNhomMucTieu and IDHTTS=@IDHTTS and IDCoCau=ISNULL(@IDCoCau,0) and IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and IDChucDanh=ISNULL(@IDChucDanh,0);
		END;
		ELSE
		BEGIN
			UPDATE TW_NhomMucTieuKetQua
			SET DiemTamTinh=@DiemHoanThanh,
				TyLeTamTinh=@TyLeHoanThanh,
				LastUpdatedDate=getdate(),
				LastUpdatedBy=@IDNhanSu
			WHERE IDHTMT=@IDHTMT AND IDNhomMucTieu=@IDNhomMucTieu and IDHTTS=@IDHTTS and IDCoCau=ISNULL(@IDCoCau,0) and IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and IDChucDanh=ISNULL(@IDChucDanh,0);
		END;
	END;
	ELSE
	BEGIN
		IF @IsDanhGia=1
		BEGIN
			INSERT INTO TW_NhomMucTieuKetQua
			(IDHTMT,IDNhomMucTieu,IDHTTS,IDCoCau,IDNguoiPhuTrach,IDChucDanh,DiemHoanThanh,TyLeHoanThanh,LastUpdatedDate,LastUpdatedBy)
			VALUES
			(@IDHTMT,@IDNhomMucTieu,@IDHTTS,ISNULL(@IDCoCau,0),ISNULL(@IDNguoiPhuTrach,0),ISNULL(@IDChucDanh,0),@DiemHoanThanh,@TyLeHoanThanh,getdate(),@IDNhanSu);
		END;
		ELSE
		BEGIN
			INSERT INTO TW_NhomMucTieuKetQua
			(IDHTMT,IDNhomMucTieu,IDHTTS,IDCoCau,IDNguoiPhuTrach,IDChucDanh,DiemTamTinh,TyLeTamTinh,LastUpdatedDate,LastUpdatedBy)
			VALUES
			(@IDHTMT,@IDNhomMucTieu,@IDHTTS,ISNULL(@IDCoCau,0),ISNULL(@IDNguoiPhuTrach,0),ISNULL(@IDChucDanh,0),@DiemHoanThanh,@TyLeHoanThanh,getdate(),@IDNhanSu);
		END;
	END;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_DanhGia_THI_TinhDiem]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_DanhGia_THI_TinhDiem]
@IDHTMT	bigint,
@IDHTTS	bigint,
@IDCoCau bigint,
@IDNguoiPhuTrach bigint,
@IDChucDanh bigint,
@IsDanhGia tinyint,
@Diem decimal(9, 5),
@MucDanhGia	nvarchar(50),
@IDNhanSu bigint,
@Overwrite bit=0
AS
BEGIN
	DECLARE @IDDanhGia bigint=0;
	DECLARE @ChuThe tinyint=0;
	IF @IDNguoiPhuTrach>0 SET @ChuThe=1;

	DECLARE @COUNT int=0;
	DECLARE @Date datetime=getdate();
	DECLARE @MaMucDanhGia nvarchar(50);
	DECLARE @TongDiem decimal(5, 2);
	DECLARE @DiemMax decimal(5, 2);
	DECLARE @DiemMin decimal(5, 2);
	DECLARE @DiemNew decimal(5, 2);
	DECLARE @IDKhachHang int;
	SELECT @DiemMax= Max(DiemDen), @DiemMin=MIN(DiemTu) FROM TW_MucDanhGia WHERE ISNULL(SuDung,1)=1;

	SET @DiemNew = @Diem;
	IF @Diem>@DiemMax SET @Diem=@DiemMax;
	IF @Diem<@DiemMin SET @Diem=@DiemMin;

	SET @TongDiem=@DiemNew;

	SELECT @IDKhachHang=IDKhachHang FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	SELECT @COUNT=COUNT(*) FROM TW_DanhGia WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and IDChucDanh=ISNULL(@IDChucDanh,0);
	IF @COUNT=0 
	BEGIN
		SELECT @MaMucDanhGia= MaMucDanhGia FROM TW_MucDanhGia WHERE IDKhachHang=@IDKhachHang AND IDChuThe=@ChuThe AND @TongDiem > DiemTu AND @TongDiem <= DiemDen AND ISNULL(SuDung,1)=1 AND ISNULL(IsDelete,0)=0 ;
		
		IF @IsDanhGia=1
		BEGIN
			INSERT INTO TW_DanhGia
			(IDHTMT,IDHTTS,IDCoCau,IDNguoiPhuTrach,IDChucDanh,Diem,TongDiem,MaMucDanhGia,Khoa,CreatedDate,CreatedBy,LastUpdatedDate,LastUpdatedBy)
			VALUES (@IDHTMT,@IDHTTS,ISNULL(@IDCoCau,0),ISNULL(@IDNguoiPhuTrach,0),ISNULL(@IDChucDanh,0),@DiemNew,@DiemNew,@MaMucDanhGia,0,@Date,@IDNhanSu,@Date,@IDNhanSu);
		END;
		ELSE
		BEGIN
			INSERT INTO TW_DanhGia
			(IDHTMT,IDHTTS,IDCoCau,IDNguoiPhuTrach,IDChucDanh,DiemTamTinh,MaMucTamTinh,Khoa,CreatedDate,CreatedBy,LastUpdatedDate,LastUpdatedBy)
			VALUES (@IDHTMT,@IDHTTS,ISNULL(@IDCoCau,0),ISNULL(@IDNguoiPhuTrach,0),ISNULL(@IDChucDanh,0),@DiemNew,@MaMucDanhGia,0,@Date,@IDNhanSu,@Date,@IDNhanSu);
		END;
		SELECT @IDDanhGia=SCOPE_IDENTITY();
	END;
	ELSE
	BEGIN
		SELECT @IDDanhGia=IDDanhGia,@TongDiem=@DiemNew+ISNULL(DiemCongTru,0)
		FROM TW_DanhGia
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and IDChucDanh=ISNULL(@IDChucDanh,0);
		
		SELECT @MaMucDanhGia= MaMucDanhGia FROM TW_MucDanhGia WHERE IDKhachHang=@IDKhachHang AND IDChuThe=@ChuThe AND @TongDiem > DiemTu AND @TongDiem <= DiemDen AND ISNULL(SuDung,1)=1 AND ISNULL(IsDelete,0)=0 ;
		
		IF @IsDanhGia=1
		BEGIN
			UPDATE TW_DanhGia
			SET Diem=@DiemNew,
				TongDiem=@TongDiem,
				MaMucDanhGia=@MaMucDanhGia,
				LastUpdatedDate=@Date,
				LastUpdatedBy=@IDNhanSu
			WHERE IDDanhGia=@IDDanhGia;
		END;
		ELSE
		BEGIN
			UPDATE TW_DanhGia
			SET DiemTamTinh=@DiemNew, MaMucTamTinh=@MaMucDanhGia
			WHERE IDDanhGia=@IDDanhGia;
		END;
	END;

	DECLARE @LoaiMucTieuKetQua TABLE(IDDanhGiaPK bigint NOT NULL,
									 IDLoaiMucTieuPK tinyint NOT NULL,
									 IDChucDanh int NOT NULL,
									 DiemTamTinh decimal(15, 5) NULL,
									 DiemHoanThanh decimal(15, 5) NULL,
									 PRIMARY KEY (IDDanhGiaPK,IDLoaiMucTieuPK)
								    );

	INSERT INTO @LoaiMucTieuKetQua (IDDanhGiaPK,IDLoaiMucTieuPK,IDChucDanh,DiemTamTinh,DiemHoanThanh)
	SELECT dg.IDDanhGia, nmt.IDLoaiMucTieu,dg.IDChucDanh, SUM(mt.DiemHoanThanh),
		SUM(
				CASE WHEN ISNULL(nkq.IDTrangThaiDuyet,0) in (4,7,10) THEN mt.DiemHoanThanh 
				ELSE 0
				END
			)
	FROM TW_DanhGia dg
	INNER JOIN TW_MucTieu mt ON dg.IDHTMT=mt.IDHTMT and dg.IDHTTS=mt.IDHTTS
	AND (
			(@ChuThe=0 AND dg.IDCoCau=mt.IDCoCau and dg.IDChucDanh=0)
			OR
			(@ChuThe=1 AND dg.IDNguoiPhuTrach=mt.IDNguoiPhuTrach and dg.IDChucDanh=mt.IDChucDanhDG)
		)
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=dg.IDHTMT
	WHERE IDDanhGia=@IDDanhGia
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	GROUP BY dg.IDDanhGia,nmt.IDLoaiMucTieu,dg.IDChucDanh;

	UPDATE TW_LoaiMucTieuKetQua 
		SET DiemTamTinh=OtherTable.DiemTamTinh,
		    DiemHoanThanh=OtherTable.DiemHoanThanh
		FROM (SELECT *
			  FROM @LoaiMucTieuKetQua) AS OtherTable
		WHERE IDDanhGia=OtherTable.IDDanhGiaPK
			AND IDLoaiMucTieu=OtherTable.IDLoaiMucTieuPK
	
	INSERT INTO TW_LoaiMucTieuKetQua (IDDanhGia,IDLoaiMucTieu,IDChucDanh,DiemTamTinh,DiemHoanThanh)
	SELECT tmp.IDDanhGiaPK,tmp.IDLoaiMucTieuPK,tmp.IDChucDanh,tmp.DiemTamTinh,tmp.DiemHoanThanh
	FROM @LoaiMucTieuKetQua tmp
	LEFT JOIN TW_LoaiMucTieuKetQua lmtkq on lmtkq.IDDanhGia=tmp.IDDanhGiaPK and lmtkq.IDLoaiMucTieu=tmp.IDLoaiMucTieuPK
	WHERE lmtkq.IDDanhGia is null;
	
	RETURN CAST(@IDDanhGia AS bigint);
END
GO
/****** Object:  StoredProcedure [dbo].[sp_DanhGia_THI_TinhDiem_All]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_DanhGia_THI_TinhDiem_All]
AS
BEGIN
	DECLARE @IDDanhGia bigint=0;
	DECLARE @TableDanhGiaBP TABLE(IDDanhGia bigint NOT NULL,STT int);
	DECLARE @TableDanhGiaNS TABLE(IDDanhGia bigint NOT NULL,STT int);

	INSERT INTO @TableDanhGiaBP(IDDanhGia,STT)
	SELECT dg.IDDanhGia, ROW_NUMBER() OVER(ORDER BY IDDanhGia ASC) as STT  
	FROM TW_DanhGia dg
	WHERE IDCoCau>0 AND dg.IDNguoiPhuTrach=0
	AND dg.IDDanhGia not in (select IDDanhGia from TW_LoaiMucTieuKetQua where IDCoCau>0 and IDNguoiPhuTrach=0);

	INSERT INTO @TableDanhGiaNS(IDDanhGia,STT)
	SELECT dg.IDDanhGia, ROW_NUMBER() OVER(ORDER BY IDDanhGia ASC) as STT  
	FROM TW_DanhGia dg
	WHERE IDCoCau=0 AND dg.IDNguoiPhuTrach>0
	AND dg.IDDanhGia not in (select IDDanhGia from TW_LoaiMucTieuKetQua where IDCoCau=0 and IDNguoiPhuTrach>0);

	DECLARE @MaxCount int;
	DECLARE @i int = 0;
	SELECT @MaxCount=COUNT(*) FROM @TableDanhGiaBP;
	IF @MaxCount>0
	BEGIN
		SET @i=0;
		WHILE @i <= @MaxCount
		BEGIN
			SET @i = @i + 1
			SELECT @IDDanhGia=IDDanhGia FROM @TableDanhGiaBP WHERE STT=@i;
			
			INSERT INTO TW_LoaiMucTieuKetQua (IDDanhGia,IDLoaiMucTieu,TyLeHoanThanh,DiemHoanThanh)
			SELECT @IDDanhGia, nmt.IDLoaiMucTieu, null,SUM(mt.DiemHoanThanh)
			FROM TW_DanhGia dg
			INNER JOIN TW_MucTieu mt ON dg.IDCoCau=mt.IDCoCau and dg.IDNguoiPhuTrach=mt.IDNguoiPhuTrach and dg.IDHTMT=mt.IDHTMT and dg.IDHTTS=mt.IDHTTS
			INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu
			INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=dg.IDHTMT
			WHERE IDDanhGia=@IDDanhGia
			GROUP BY nmt.IDLoaiMucTieu
		END
	END;

	SELECT @MaxCount=COUNT(*) FROM @TableDanhGiaNS;
	IF @MaxCount>0
	BEGIN
		SET @i=0;
		WHILE @i <= @MaxCount
		BEGIN
			SET @i = @i + 1
			SELECT @IDDanhGia=IDDanhGia FROM @TableDanhGiaNS WHERE STT=@i;
			
			INSERT INTO TW_LoaiMucTieuKetQua (IDDanhGia,IDLoaiMucTieu,DiemTamTinh,DiemHoanThanh)
			SELECT @IDDanhGia, nmt.IDLoaiMucTieu, SUM(mt.DiemHoanThanh),
				SUM(
					 CASE WHEN ISNULL(nkq.IDTrangThaiDuyet,0) in (4,7,10) THEN mt.DiemHoanThanh 
					 ELSE 0
					 END
				   )
			FROM TW_DanhGia dg
			INNER JOIN TW_MucTieu mt ON dg.IDCoCau=mt.IDCoCau and dg.IDNguoiPhuTrach=mt.IDNguoiPhuTrach and dg.IDHTMT=mt.IDHTMT and dg.IDHTTS=mt.IDHTTS
			LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
			INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu
			INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=dg.IDHTMT
			WHERE IDDanhGia=@IDDanhGia
			AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
			GROUP BY nmt.IDLoaiMucTieu;
		END
	END;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_DUYET_MucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_DUYET_MucTieu]
@IDHTMT	bigint = null,
@IDMucTieu bigint,
@IDTrangThaiDuyet tinyint,
@IDQuyenCap int,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	--Kiểm tra trạng thái duyệt tổng hợp + duyệt nhập kết quả
	declare @iResult int=0;
	exec @iResult = sp_LAY_TrangThaiDuyet @IDMucTieu
	if @iResult!=0
	BEGIN
		RETURN @iResult;
	END;

	DECLARE @IDTrangThaiDuyet1 tinyint
	DECLARE @IDTrangThaiDuyet2 tinyint
	DECLARE @IDTrangThaiDuyet3 tinyint
	DECLARE @IDTrangThaiDuyetCu tinyint
	DECLARE @IDTrangThaiDuyetMoi tinyint
	
	SELECT @IDTrangThaiDuyet1=ISNULL(IDTrangThaiDuyet1,0),
		   @IDTrangThaiDuyet2=ISNULL(IDTrangThaiDuyet2,0),
		   @IDTrangThaiDuyet3=ISNULL(IDTrangThaiDuyet3,0),
		   @IDTrangThaiDuyetCu=ISNULL(IDTrangThaiDuyet,1)
	FROM TW_MucTieu
	WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;
	
	IF @IDQuyenCap=1
	BEGIN
		if @IDTrangThaiDuyet=0
			SELECT @IDTrangThaiDuyetMoi=1;--Chờ duyệt/ hủy duyệt
		ELSE IF @IDTrangThaiDuyet=1
			SELECT @IDTrangThaiDuyetMoi=4;--Cấp 1 đã duyệt
		ELSE IF @IDTrangThaiDuyet=2
			SELECT @IDTrangThaiDuyetMoi=3;--Cấp 1 trả về
		ELSE IF @IDTrangThaiDuyet=3
			SELECT @IDTrangThaiDuyetMoi=2;--Cấp 1 không duyệt
	END;
	ELSE IF @IDQuyenCap=2
	BEGIN
		if @IDTrangThaiDuyet=0--Cấp 2 hủy duyệt
		BEGIN
			if @IDTrangThaiDuyet1=0
				SELECT @IDTrangThaiDuyetMoi=1;--Chờ duyệt
			else if @IDTrangThaiDuyet1=1
				SELECT @IDTrangThaiDuyetMoi=4;--Cấp 1 đã duyệt
			else if @IDTrangThaiDuyet1=2
				SELECT @IDTrangThaiDuyetMoi=3;--Cấp 1 trả về
			else if @IDTrangThaiDuyet1=3
				SELECT @IDTrangThaiDuyetMoi=2;--Cấp 1 không duyệt
		END;
		ELSE IF @IDTrangThaiDuyet=1
			SELECT @IDTrangThaiDuyetMoi=7;--Cấp 2 đã duyệt
		ELSE IF @IDTrangThaiDuyet=2
			SELECT @IDTrangThaiDuyetMoi=6;--Cấp 2 trả về
		ELSE IF @IDTrangThaiDuyet=3
			SELECT @IDTrangThaiDuyetMoi=5;--Cấp 2 không duyệt
	END;
	ELSE IF @IDQuyenCap=3
	BEGIN
		if @IDTrangThaiDuyet=0--Cấp 3 hủy duyệt
		BEGIN
			IF @IDTrangThaiDuyet2=0--Cấp 2 hủy duyệt
			BEGIN
				if @IDTrangThaiDuyet1=0
					SELECT @IDTrangThaiDuyetMoi=1;--Chờ duyệt
				else if @IDTrangThaiDuyet1=1
					SELECT @IDTrangThaiDuyetMoi=4;--Cấp 1 đã duyệt
				else if @IDTrangThaiDuyet1=2
					SELECT @IDTrangThaiDuyetMoi=3;--Cấp 1 trả về
				else if @IDTrangThaiDuyet1=3
					SELECT @IDTrangThaiDuyetMoi=2;--Cấp 1 không duyệt
			END;
			ELSE IF @IDTrangThaiDuyet2=1
				SELECT @IDTrangThaiDuyetMoi=7;--Cấp 2 đã duyệt
			ELSE IF @IDTrangThaiDuyet2=2
				SELECT @IDTrangThaiDuyetMoi=6;--Cấp 2 trả về
			ELSE IF @IDTrangThaiDuyet2=3
				SELECT @IDTrangThaiDuyetMoi=5;--Cấp 2 không duyệt
		END;
		ELSE IF @IDTrangThaiDuyet=1
			SELECT @IDTrangThaiDuyetMoi=10;--Cấp 3 đã duyệt
		ELSE IF @IDTrangThaiDuyet=2
			SELECT @IDTrangThaiDuyetMoi=9;--Cấp 3 trả về
		ELSE IF @IDTrangThaiDuyet=3
			SELECT @IDTrangThaiDuyetMoi=8;--Cấp 3 không duyệt
	END;

	IF @IDTrangThaiDuyetCu=1 and @IDTrangThaiDuyet=0
		RETURN -10;--Chờ duyệt cấp 1
	IF @IDTrangThaiDuyetCu=4 and @IDTrangThaiDuyet=0 and @IDQuyenCap=2
		RETURN -11;--Chờ duyệt cấp 2
	IF @IDTrangThaiDuyetCu in (4,7) and @IDTrangThaiDuyet=0 and @IDQuyenCap=3
		RETURN -21;--Chờ duyệt cấp 3
	
	IF @IDTrangThaiDuyetCu=2 
		RETURN -13;--Cấp 1 không duyệt
	IF @IDTrangThaiDuyetCu=5 
		RETURN -23;--Cấp 2 không duyệt
	IF @IDTrangThaiDuyetCu=8 
		RETURN -33;--Cấp 3 không duyệt

	IF @IDTrangThaiDuyetCu=@IDTrangThaiDuyetMoi RETURN 0;--Không thay đổi gì

	--0: Chờ duyệt	-	1: Đã duyệt	-	2: Trả về -	3: Không duyệt
	DECLARE @COUNT int=0;
	--DECLARE @IDTrangThaiDuyet tinyint=1;--Đã duyệt
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	--1: nhân sự, 2: Quản lý, 3: Bộ phận, 4: Chỉ định BP, 5: Toàn quyền
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4--Khong xem BP con
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT @COUNT=COUNT(*)
	FROM TW_MucTieu mt
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	WHERE mt.IDHTMT=@IDHTMT and mt.IDMucTieu=@IDMucTieu
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(
					(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
					OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
				)
			)
		)
	
	IF @COUNT=0
	BEGIN
		RETURN -1;--Không có quyền
	END;

	IF @IDQuyenCap=1
	BEGIN
		--0: Chờ duyệt	-	1: Đã duyệt	-	2: Trả về -	3: Không duyệt
		IF @IDTrangThaiDuyetCu=10
			RETURN -31;--Cấp 3 đã duyệt
		IF @IDTrangThaiDuyetCu=9 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -32;--Cấp 3 trả về
		IF @IDTrangThaiDuyetCu=8 
			RETURN -33;--Cấp 3 không duyệt
		
		IF @IDTrangThaiDuyetCu=7 
			RETURN -21;--Cấp 2 đã duyệt
		IF @IDTrangThaiDuyetCu=6 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -22;--Cấp 2 trả về
		IF @IDTrangThaiDuyetCu=5 
			RETURN -23;--Cấp 2 không duyệt
		
		IF @IDTrangThaiDuyetCu=4 AND @IDTrangThaiDuyet !=0
			RETURN -11;--Cấp 1 đã duyệt
		IF @IDTrangThaiDuyetCu=3 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -12;--Cấp 1 trả về
		IF @IDTrangThaiDuyetCu=2 
			RETURN -13;--Cấp 1 không duyệt

		IF @IDTrangThaiDuyetCu=1 AND @IDTrangThaiDuyet=0
			RETURN -10;--Chờ duyệt cấp 1
		
		if @IDTrangThaiDuyet=1
			UPDATE TW_MucTieu
			SET IDTrangThaiDuyet=@IDTrangThaiDuyetMoi,
				IDTrangThaiDuyet1=@IDTrangThaiDuyet,
				NguoiDuyet1=@IDNhanSu,
				NgayDuyet1=getdate()
			WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;
		else
			UPDATE TW_MucTieu
			SET IDTrangThaiDuyet=@IDTrangThaiDuyetMoi,
				IDTrangThaiDuyet1=@IDTrangThaiDuyet,
				NgayHuyDuyet1=getdate()
			WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;
	END;
	ELSE IF @IDQuyenCap=2
	BEGIN
		--0: Chờ duyệt	-	1: Đã duyệt	-	2: Trả về -	3: Không duyệt
		IF @IDTrangThaiDuyetCu=10
			RETURN -31;--Cấp 3 đã duyệt
		IF @IDTrangThaiDuyetCu=9 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -32;--Cấp 3 trả về
		IF @IDTrangThaiDuyetCu=8 
			RETURN -33;--Cấp 3 không duyệt
		
		IF @IDTrangThaiDuyetCu=7 AND @IDTrangThaiDuyet!=0
			RETURN -21;--Cấp 2 đã duyệt
		IF @IDTrangThaiDuyetCu=6 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -22;--Cấp 2 trả về
		IF @IDTrangThaiDuyetCu=5 
			RETURN -23;--Cấp 2 không duyệt
		
		IF @IDTrangThaiDuyetCu=4 AND @IDTrangThaiDuyet=0
			RETURN -11;--Chờ duyệt cấp 2
		IF @IDTrangThaiDuyetCu=3 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -12;--Cấp 1 trả về
		IF @IDTrangThaiDuyetCu=2 
			RETURN -13;--Cấp 1 không duyệt

		IF @IDTrangThaiDuyetCu=1 AND @IDTrangThaiDuyet=0
			RETURN -10;--Chờ duyệt cấp 1

		if @IDTrangThaiDuyet=1
			UPDATE TW_MucTieu
			SET IDTrangThaiDuyet=@IDTrangThaiDuyetMoi,
				IDTrangThaiDuyet2=@IDTrangThaiDuyet,
				NguoiDuyet2=@IDNhanSu,
				NgayDuyet2=getdate()
			WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;
		else
		UPDATE TW_MucTieu
			SET IDTrangThaiDuyet=@IDTrangThaiDuyetMoi,
				IDTrangThaiDuyet2=@IDTrangThaiDuyet,
				NgayHuyDuyet2=getdate()
			WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;
	END;
	ELSE IF @IDQuyenCap=3
	BEGIN
		--0: Chờ duyệt	-	1: Đã duyệt	-	2: Trả về -	3: Không duyệt
		IF @IDTrangThaiDuyetCu=10 AND @IDTrangThaiDuyet!=0
			RETURN -31;--Cấp 3 đã duyệt
		IF @IDTrangThaiDuyetCu=9 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -32;--Cấp 3 trả về
		IF @IDTrangThaiDuyetCu=8 
			RETURN -33;--Cấp 3 không duyệt
		
		IF @IDTrangThaiDuyetCu=7 AND @IDTrangThaiDuyet=0
			RETURN -21;--Chờ duyệt cấp 3
		IF @IDTrangThaiDuyetCu=6 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -22;--Cấp 2 trả về
		IF @IDTrangThaiDuyetCu=5 
			RETURN -23;--Cấp 2 không duyệt
		
		IF @IDTrangThaiDuyetCu=4 AND @IDTrangThaiDuyet=0
			RETURN -11;--Chờ duyệt cấp 2
		IF @IDTrangThaiDuyetCu=3 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -12;--Cấp 1 trả về
		IF @IDTrangThaiDuyetCu=2 
			RETURN -13;--Cấp 1 không duyệt

		IF @IDTrangThaiDuyetCu=1 AND @IDTrangThaiDuyet=0
			RETURN -10;--Chờ duyệt cấp 1
		
		if @IDTrangThaiDuyet=1
			UPDATE TW_MucTieu
			SET IDTrangThaiDuyet=@IDTrangThaiDuyetMoi,
				IDTrangThaiDuyet3=@IDTrangThaiDuyet,
				NguoiDuyet3=@IDNhanSu,
				NgayDuyet3=getdate()
			WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;
		else
			UPDATE TW_MucTieu
			SET IDTrangThaiDuyet=@IDTrangThaiDuyetMoi,
				IDTrangThaiDuyet3=@IDTrangThaiDuyet,
				NgayHuyDuyet3=getdate()
			WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;
	END;

END
GO
/****** Object:  StoredProcedure [dbo].[sp_DUYET_NhapKetQua]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_DUYET_NhapKetQua]
@IDHTMT	bigint = null,
@IDMucTieu bigint,
@IDTrangThaiDuyet tinyint,
@IDQuyenCap int,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int

AS
BEGIN
	--Kiểm tra trạng thái duyệt tổng hợp
	declare @iResult int=0;
	exec @iResult = sp_LAY_TrangThaiDuyetTongHop @IDMucTieu
	if @iResult!=0
	BEGIN
		RETURN @iResult;
	END;

	DECLARE @IDTrangThaiDuyet1 tinyint
	DECLARE @IDTrangThaiDuyet2 tinyint
	DECLARE @IDTrangThaiDuyet3 tinyint
	DECLARE @IDTrangThaiDuyetCu tinyint
	DECLARE @IDTrangThaiDuyetMoi tinyint
	
	SELECT @IDTrangThaiDuyet1=ISNULL(IDTrangThaiDuyet1,0),
		   @IDTrangThaiDuyet2=ISNULL(IDTrangThaiDuyet2,0),
		   @IDTrangThaiDuyet3=ISNULL(IDTrangThaiDuyet3,0),
		   @IDTrangThaiDuyetCu=ISNULL(IDTrangThaiDuyet,1)
	FROM TW_MucTieuNhapKetQua
	WHERE IDMucTieu=@IDMucTieu

	IF @IDQuyenCap=1
	BEGIN
		if @IDTrangThaiDuyet=0
			SELECT @IDTrangThaiDuyetMoi=1;--Chờ duyệt/ hủy duyệt
		ELSE IF @IDTrangThaiDuyet=1
			SELECT @IDTrangThaiDuyetMoi=4;--Cấp 1 đã duyệt
		ELSE IF @IDTrangThaiDuyet=2
			SELECT @IDTrangThaiDuyetMoi=3;--Cấp 1 trả về
		ELSE IF @IDTrangThaiDuyet=3
			SELECT @IDTrangThaiDuyetMoi=2;--Cấp 1 không duyệt
	END;
	ELSE IF @IDQuyenCap=2
	BEGIN
		if @IDTrangThaiDuyet=0--Cấp 2 hủy duyệt
		BEGIN
			if @IDTrangThaiDuyet1=0
				SELECT @IDTrangThaiDuyetMoi=1;--Chờ duyệt
			else if @IDTrangThaiDuyet1=1
				SELECT @IDTrangThaiDuyetMoi=4;--Cấp 1 đã duyệt
			else if @IDTrangThaiDuyet1=2
				SELECT @IDTrangThaiDuyetMoi=3;--Cấp 1 trả về
			else if @IDTrangThaiDuyet1=3
				SELECT @IDTrangThaiDuyetMoi=2;--Cấp 1 không duyệt
		END;
		ELSE IF @IDTrangThaiDuyet=1
			SELECT @IDTrangThaiDuyetMoi=7;--Cấp 2 đã duyệt
		ELSE IF @IDTrangThaiDuyet=2
			SELECT @IDTrangThaiDuyetMoi=6;--Cấp 2 trả về
		ELSE IF @IDTrangThaiDuyet=3
			SELECT @IDTrangThaiDuyetMoi=5;--Cấp 2 không duyệt
	END;
	ELSE IF @IDQuyenCap=3
	BEGIN
		if @IDTrangThaiDuyet=0--Cấp 3 hủy duyệt
		BEGIN
			IF @IDTrangThaiDuyet2=0--Cấp 2 hủy duyệt
			BEGIN
				if @IDTrangThaiDuyet1=0
					SELECT @IDTrangThaiDuyetMoi=1;--Chờ duyệt
				else if @IDTrangThaiDuyet1=1
					SELECT @IDTrangThaiDuyetMoi=4;--Cấp 1 đã duyệt
				else if @IDTrangThaiDuyet1=2
					SELECT @IDTrangThaiDuyetMoi=3;--Cấp 1 trả về
				else if @IDTrangThaiDuyet1=3
					SELECT @IDTrangThaiDuyetMoi=2;--Cấp 1 không duyệt
			END;
			ELSE IF @IDTrangThaiDuyet2=1
				SELECT @IDTrangThaiDuyetMoi=7;--Cấp 2 đã duyệt
			ELSE IF @IDTrangThaiDuyet2=2
				SELECT @IDTrangThaiDuyetMoi=6;--Cấp 2 trả về
			ELSE IF @IDTrangThaiDuyet2=3
				SELECT @IDTrangThaiDuyetMoi=5;--Cấp 2 không duyệt
		END;
		ELSE IF @IDTrangThaiDuyet=1
			SELECT @IDTrangThaiDuyetMoi=10;--Cấp 3 đã duyệt
		ELSE IF @IDTrangThaiDuyet=2
			SELECT @IDTrangThaiDuyetMoi=9;--Cấp 3 trả về
		ELSE IF @IDTrangThaiDuyet=3
			SELECT @IDTrangThaiDuyetMoi=8;--Cấp 3 không duyệt
	END;
	
	----0: Chờ duyệt	-	1: Đã duyệt	-	2: Trả về -	3: Không duyệt
	DECLARE @COUNT int=0;
	SELECT @COUNT=COUNT(*)
	FROM TW_MucTieuNhapKetQua
	WHERE IDMucTieu=@IDMucTieu
	
	IF @COUNT=0
	BEGIN
		INSERT INTO TW_MucTieuNhapKetQua(IDMucTieu,IDTrangThaiDuyet,IDTrangThaiDuyet3,NguoiDuyet3,NgayDuyet3)
		VALUES (@IDMucTieu,@IDTrangThaiDuyetMoi,@IDTrangThaiDuyet,@IDNhanSu,getdate());
		return 0;
	END;
	--Update trang thai Muc Tieu
	--0: Chờ duyệt	-	1: Đã duyệt	-	2: Trả về -	3: Không duyệt
	IF @IDTrangThaiDuyetMoi=1
		Update TW_MucTieu set IDTrangThaiMucTieu=3--Chuyển trạng thái kết thúc
		WHERE IDMucTieu=@IDMucTieu AND ISNULL(IDTrangThaiMucTieu,0)<3;
	ELSE 
		Update TW_MucTieu set IDTrangThaiMucTieu=2 --Chuyển trạng thái đang làm
		WHERE IDMucTieu=@IDMucTieu AND ISNULL(IDTrangThaiMucTieu,0)<3;
		
	IF @IDQuyenCap=1
	BEGIN
		--0: Chờ duyệt	-	1: Đã duyệt	-	2: Trả về -	3: Không duyệt
		IF @IDTrangThaiDuyetCu=10
			RETURN -31;--Cấp 3 đã duyệt
		IF @IDTrangThaiDuyetCu=9 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -32;--Cấp 3 trả về
		IF @IDTrangThaiDuyetCu=8 
			RETURN -33;--Cấp 3 không duyệt
		
		IF @IDTrangThaiDuyetCu=7 
			RETURN -21;--Cấp 2 đã duyệt
		IF @IDTrangThaiDuyetCu=6 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -22;--Cấp 2 trả về
		IF @IDTrangThaiDuyetCu=5 
			RETURN -23;--Cấp 2 không duyệt
		
		IF @IDTrangThaiDuyetCu=4 AND @IDTrangThaiDuyet!=0
			RETURN -11;--Cấp 1 đã duyệt
		IF @IDTrangThaiDuyetCu=1 AND @IDTrangThaiDuyet=0
			RETURN -10;--Chờ duyệt cấp 1

		UPDATE TW_MucTieuNhapKetQua
		SET IDTrangThaiDuyet=@IDTrangThaiDuyetMoi,
			IDTrangThaiDuyet1=@IDTrangThaiDuyet,
			SoThucTeNgay1=ISNULL(SoThucTeNgay1,SoThucTeNgay),
			SoThucTeSo1=ISNULL(SoThucTeSo1,SoThucTeSo),
			SoThucTeTyLe1=ISNULL(SoThucTeTyLe1,SoThucTeTyLe),
			NguoiDuyet1=@IDNhanSu,
			NgayDuyet1=getdate()
		WHERE IDMucTieu=@IDMucTieu
		AND (ISNULL(IDTrangThaiDuyet,0)!=@IDTrangThaiDuyetMoi);

	END;
	ELSE IF @IDQuyenCap=2
	BEGIN
		--0: Chờ duyệt	-	1: Đã duyệt	-	2: Trả về -	3: Không duyệt
		IF @IDTrangThaiDuyetCu=10
			RETURN -31;--Cấp 3 đã duyệt
		IF @IDTrangThaiDuyetCu=9 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -32;--Cấp 3 trả về
		IF @IDTrangThaiDuyetCu=8 
			RETURN -33;--Cấp 3 không duyệt
		
		IF @IDTrangThaiDuyetCu=7 AND @IDTrangThaiDuyet!=0
			RETURN -21;--Cấp 2 đã duyệt
		IF @IDTrangThaiDuyetCu=6 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -22;--Cấp 2 trả về
		IF @IDTrangThaiDuyetCu=5 
			RETURN -23;--Cấp 2 không duyệt
		
		IF @IDTrangThaiDuyetCu=4 AND @IDTrangThaiDuyet=0
			RETURN -11;--Chờ duyệt cấp 2
		IF @IDTrangThaiDuyetCu=3 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -12;--Cấp 1 trả về
		IF @IDTrangThaiDuyetCu=2 
			RETURN -13;--Cấp 1 không duyệt

		IF @IDTrangThaiDuyetCu=1 AND @IDTrangThaiDuyet=0
			RETURN -10;--Chờ duyệt cấp 1

		UPDATE TW_MucTieuNhapKetQua
		SET IDTrangThaiDuyet=@IDTrangThaiDuyetMoi,
			IDTrangThaiDuyet2=@IDTrangThaiDuyet,
			SoThucTeNgay2=ISNULL(SoThucTeNgay2,ISNULL(SoThucTeNgay1,SoThucTeNgay)),
			SoThucTeSo2=ISNULL(SoThucTeSo2,ISNULL(SoThucTeSo1,SoThucTeSo)),
			SoThucTeTyLe2=ISNULL(SoThucTeTyLe2,ISNULL(SoThucTeTyLe1,SoThucTeTyLe)),
			NguoiDuyet2=@IDNhanSu,
			NgayDuyet2=getdate()
		WHERE IDMucTieu=@IDMucTieu
		AND (ISNULL(IDTrangThaiDuyet,0)!=@IDTrangThaiDuyetMoi);

	END;
	ELSE IF @IDQuyenCap=3
	BEGIN
		--0: Chờ duyệt	-	1: Đã duyệt	-	2: Trả về -	3: Không duyệt
		IF @IDTrangThaiDuyetCu=10 AND @IDTrangThaiDuyet!=0
			RETURN -31;--Cấp 3 đã duyệt
		IF @IDTrangThaiDuyetCu=9 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -32;--Cấp 3 trả về
		IF @IDTrangThaiDuyetCu=8 
			RETURN -33;--Cấp 3 không duyệt
		
		IF @IDTrangThaiDuyetCu=7 AND @IDTrangThaiDuyet=0
			RETURN -21;--Chờ duyệt cấp 3
		IF @IDTrangThaiDuyetCu=6 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -22;--Cấp 2 trả về
		IF @IDTrangThaiDuyetCu=5 
			RETURN -23;--Cấp 2 không duyệt
		
		IF @IDTrangThaiDuyetCu=4 AND @IDTrangThaiDuyet=0
			RETURN -11;--Chờ duyệt cấp 2
		IF @IDTrangThaiDuyetCu=3 AND @IDTrangThaiDuyet in (0,2) 
			RETURN -12;--Cấp 1 trả về
		IF @IDTrangThaiDuyetCu=2 
			RETURN -13;--Cấp 1 không duyệt

		IF @IDTrangThaiDuyetCu=1 AND @IDTrangThaiDuyet=0
			RETURN -10;--Chờ duyệt cấp 1
		
		UPDATE TW_MucTieuNhapKetQua
		SET IDTrangThaiDuyet=@IDTrangThaiDuyetMoi,
			IDTrangThaiDuyet3=@IDTrangThaiDuyet,
			SoThucTeNgay3=ISNULL(SoThucTeNgay3,ISNULL(SoThucTeNgay2,ISNULL(SoThucTeNgay1,SoThucTeNgay))),
			SoThucTeSo3=ISNULL(SoThucTeSo3,ISNULL(SoThucTeSo2,ISNULL(SoThucTeSo1,SoThucTeSo))),
			SoThucTeTyLe3=ISNULL(SoThucTeTyLe3,ISNULL(SoThucTeTyLe2,ISNULL(SoThucTeTyLe1,SoThucTeTyLe))),
			NguoiDuyet3=@IDNhanSu,
			NgayDuyet3=getdate()
		WHERE IDMucTieu=@IDMucTieu
		AND (ISNULL(IDTrangThaiDuyet,0)!=@IDTrangThaiDuyetMoi);
	END;

	IF @IDTrangThaiDuyetMoi=1
	BEGIN
		UPDATE TW_MucTieu SET IDTrangThaiMucTieu=2 WHERE IDMucTieu=@IDMucTieu AND IDTrangThaiMucTieu=3;
	END;
	IF @IDTrangThaiDuyet=1
	BEGIN
		UPDATE TW_MucTieu SET IDTrangThaiMucTieu=3 WHERE IDMucTieu=@IDMucTieu;
	END;

END
GO
/****** Object:  StoredProcedure [dbo].[sp_DUYET_ThietLap_TrongSo]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_DUYET_ThietLap_TrongSo]
@IDHTMT	bigint,
@IDHTTS	bigint,
@ChuThe tinyint,
@IDMucTieu bigint,
@IDCoCau bigint,
@IDNguoiPhuTrach bigint,
@TrongSo decimal(5, 2),
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Count int=0;

	IF (@IDMucTieu>0)
	BEGIN
		UPDATE TW_MucTieuTrongSo 
			SET DaDuyet=1
			WHERE IDHTMT=@IDHTMT and IDHTTS=@IDHTTS and IDMucTieu=@IDMucTieu 
			AND (
					(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
					OR 
					(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
				);
	END;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_EXPORT_DSMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_EXPORT_DSMucTieu]
@IDHTMT	bigint = null,
@IDCha bigint=null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@IDTrangThaiDuyet tinyint=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@IDCapDuyet int,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	--@ChuThe: 0-Tổ chức, 1-Cá nhân
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (@IDCoCau IS NULL AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
	END;

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	--1: nhân sự, 2: Quản lý, 3: Bộ phận, 4: Chỉ định BP, 5: Toàn quyền
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4--Khong xem BP con
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);
	
	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND mt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
		AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
		AND (@IDTrangThaiDuyet Is null 
			OR (@IDTrangThaiDuyet=0 AND ISNULL(mt.IDTrangThaiDuyet,0) = 1)
			OR (@IDTrangThaiDuyet=1 AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10))
			OR (@IDTrangThaiDuyet=2 AND ISNULL(mt.IDTrangThaiDuyet,0) in (3,6,9))
			OR (@IDTrangThaiDuyet=3 AND ISNULL(mt.IDTrangThaiDuyet,0) in (2,5,8))
		)
		AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
		AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	SELECT htmt.MaHTMT,mt.MaMucTieu,mt.TenMucTieu,nmt.TenNhomMucTieu,mtc.MaMucTieu as MaMucTieuCha,mtc.TenMucTieu as TenMucTieuCha,mut.TenMucUuTien,lmt.TenLoaiMucTieu,kdl.TenKieuDuLieu,dvt.TenDonViTinh,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,
	mt.TrongSo,lts.TenLoaiTanSuat,htts.TenTanSuat,mt.NgayBatDau,mt.KyHan,cc.MaCoCau as MaChuTheChiTieu,cc.TenCoCau as TenChuTheChiTieu,npt.MaNhanSu,npt.HoVaTen as HoVaTen,cd.MaChucDanh,cd.TenChucDanh,ccpt.MaCoCau as MaCoCau,ccpt.TenCoCau as TenCoCau,mt.CTDiemChiTieu,mt.CTDienDai,
	null as ListMaThanhVien,qn.TenQuyenNhap,null as ListDoiTuongNhap,null as ListDoiTuongDuyet,mt.IDQuyenNhap,mt.IDQuyenDuyet,tmpTV.dsThanhVien,
	CASE 
		WHEN mt.IDQuyenNhap=2 THEN tmpNhapCD.dsQuyenNhap
		WHEN mt.IDQuyenNhap=3 THEN tmpNhapNS.dsQuyenNhap
		ELSE null
	END AS dsQuyenNhap,
	qd.TenQuyenDuyet,
	CASE 
		WHEN mt.IDQuyenDuyet=2 THEN tmpDuyetCD.dsQuyenDuyet
		WHEN mt.IDQuyenDuyet=3 THEN tmpDuyetNS.dsQuyenDuyet
		ELSE null
	END AS dsQuyenDuyet,
	qd2.TenQuyenDuyet as TenQuyenDuyet2,
	CASE 
		WHEN mt.IDQuyenDuyet2=2 THEN tmpDuyetCD2.dsQuyenDuyet
		WHEN mt.IDQuyenDuyet2=3 THEN tmpDuyetNS2.dsQuyenDuyet
		ELSE null
	END AS dsQuyenDuyet2,
	qd3.TenQuyenDuyet as TenQuyenDuyet3,
	CASE 
		WHEN mt.IDQuyenDuyet3=2 THEN tmpDuyetCD3.dsQuyenDuyet
		WHEN mt.IDQuyenDuyet3=3 THEN tmpDuyetNS3.dsQuyenDuyet
		ELSE null
	END AS dsQuyenDuyet3,
	ROW_NUMBER() OVER (ORDER BY lmt.ThuTu,nmt.ThuTuCha, nmt.ThuTu,nmt.CapBac, mt.MaThuMuc) AS STT
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN TW_MucTieu mtc on mtc.IDHTMT=mt.IDHTMT and mtc.IDMucTieu=mt.IDMucTieuCha
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0))
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau

	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=npt.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN ENUM_KieuDuLieu kdl on kdl.IDKieuDuLieu=dvt.IDKieuDuLieu
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=mt.IDHTMT and htts.IDHTTS=mt.IDHTTS and htts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=cc.IDNhomCap and nc.IDKhachHang=@IDKhachHang
	LEFT JOIN ENUM_TrangThaiMucTieu ttmt on ttmt.IDTrangThaiMucTieu=mt.IDTrangThaiMucTieu
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN ENUM_MucUuTien mut on mut.IDMucUuTien=mt.IDMucUuTien
	LEFT JOIN ENUM_QuyenNhap qn on qn.IDQuyenNhap=mt.IDQuyenNhap
	LEFT JOIN ENUM_QuyenDuyet qd on qd.IDQuyenDuyet=mt.IDQuyenDuyet
	LEFT JOIN (SELECT tv.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),ns.MaNhanSu), ',') AS dsThanhVien 
				FROM TW_ThanhVien tv
				INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=tv.IDNhanSu
				GROUP BY tv.IDMucTieu) tmpTV on tmpTV.IDMucTieu=mt.IDMucTieu
	LEFT JOIN (SELECT dtn.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),cd.MaChucDanh), ',') AS dsQuyenNhap 
				FROM TW_DoiTuongNhap dtn 
				INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=dtn.IDDoiTuong
				GROUP BY dtn.IDMucTieu) tmpNhapCD on tmpNhapCD.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=2
	LEFT JOIN ENUM_QuyenDuyetCap qd2 on qd2.IDQuyenDuyet=mt.IDQuyenDuyet2
	LEFT JOIN (SELECT dtn.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),ns.MaNhanSu), ',') AS dsQuyenNhap 
				FROM TW_DoiTuongNhap dtn 
				INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=dtn.IDDoiTuong
				GROUP BY dtn.IDMucTieu) tmpNhapNS on tmpNhapNS.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=3
	LEFT JOIN (SELECT dtd.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),cd.MaChucDanh), ',') AS dsQuyenDuyet 
				FROM TW_DoiTuongDuyet dtd 
				INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=dtd.IDDoiTuong
				GROUP BY dtd.IDMucTieu) tmpDuyetCD on tmpDuyetCD.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=2
	LEFT JOIN ENUM_QuyenDuyetCap qd3 on qd3.IDQuyenDuyet=mt.IDQuyenDuyet3
	LEFT JOIN (SELECT dtd.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),ns.MaNhanSu), ',') AS dsQuyenDuyet 
				FROM TW_DoiTuongDuyet dtd 
				INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=dtd.IDDoiTuong
				GROUP BY dtd.IDMucTieu) tmpDuyetNS on tmpDuyetNS.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=3
	LEFT JOIN (SELECT dtd.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),cd.MaChucDanh), ',') AS dsQuyenDuyet 
				FROM TW_DoiTuongDuyet2 dtd 
				INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=dtd.IDDoiTuong
				GROUP BY dtd.IDMucTieu) tmpDuyetCD2 on tmpDuyetCD2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=2
	LEFT JOIN (SELECT dtd.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),ns.MaNhanSu), ',') AS dsQuyenDuyet 
				FROM TW_DoiTuongDuyet2 dtd 
				INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=dtd.IDDoiTuong
				GROUP BY dtd.IDMucTieu) tmpDuyetNS2 on tmpDuyetNS2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=3
	LEFT JOIN (SELECT dtd.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),cd.MaChucDanh), ',') AS dsQuyenDuyet 
				FROM TW_DoiTuongDuyet3 dtd 
				INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=dtd.IDDoiTuong
				GROUP BY dtd.IDMucTieu) tmpDuyetCD3 on tmpDuyetCD3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=2
	LEFT JOIN (SELECT dtd.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),ns.MaNhanSu), ',') AS dsQuyenDuyet 
				FROM TW_DoiTuongDuyet3 dtd 
				INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=dtd.IDDoiTuong
				GROUP BY dtd.IDMucTieu) tmpDuyetNS3 on tmpDuyetNS3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=3
	
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@IDTrangThaiDuyet Is null 
			OR (@IDTrangThaiDuyet=0 AND ISNULL(mt.IDTrangThaiDuyet,0) = 1)
			OR (@IDTrangThaiDuyet=1 AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10))
			OR (@IDTrangThaiDuyet=2 AND ISNULL(mt.IDTrangThaiDuyet,0) in (3,6,9))
			OR (@IDTrangThaiDuyet=3 AND ISNULL(mt.IDTrangThaiDuyet,0) in (2,5,8))
		)
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY lmt.ThuTu, nmt.ThuTuCha, nmt.ThuTu,nmt.IDNhomMucTieu, STT;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_EXPORT_DSMucTieuCongThuc]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_EXPORT_DSMucTieuCongThuc]
@IDHTMT	bigint = null,
@IDCha bigint=null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@IDTrangThaiDuyet tinyint=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@IDCapDuyet int,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	--@ChuThe: 0-Tổ chức, 1-Cá nhân
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (@IDCoCau IS NULL AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
	END;

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	--1: nhân sự, 2: Quản lý, 3: Bộ phận, 4: Chỉ định BP, 5: Toàn quyền
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4--Khong xem BP con
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);
	
	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND mt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
		AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
		AND (@IDTrangThaiDuyet Is null 
			OR (@IDTrangThaiDuyet=0 AND ISNULL(mt.IDTrangThaiDuyet,0) = 1)
			OR (@IDTrangThaiDuyet=1 AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10))
			OR (@IDTrangThaiDuyet=2 AND ISNULL(mt.IDTrangThaiDuyet,0) in (3,6,9))
			OR (@IDTrangThaiDuyet=3 AND ISNULL(mt.IDTrangThaiDuyet,0) in (2,5,8))
		)
		AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
		AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	SELECT htmt.MaHTMT, mt.IDMucTieu,mt.MaMucTieu,mt.TenMucTieu,mt.CTSoThucTe,yt.MaMucTieuTinh,htmtt.MaHTMT as YT_MaHTMT,mtt.IDMucTieu as YT_IDMucTieu,mtt.MaMucTieu as YT_MaMucTieu,mtt.TenMucTieu as YT_TenMucTieu
	FROM TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN TW_YeuToTinhSoThucTe yt on yt.IDMucTieu=mt.IDMucTieu
	LEFT JOIN TW_MucTieu mtt on mtt.IDMucTieu=yt.IDMucTieuTinh
	LEFT JOIN TW_HeThongMucTieu htmtt on htmtt.IDHTMT=mtt.IDHTMT
	LEFT JOIN TW_MucTieu mtc on mtc.IDHTMT=mt.IDHTMT and mtc.IDMucTieu=mt.IDMucTieuCha
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0))
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau

	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@IDTrangThaiDuyet Is null 
			OR (@IDTrangThaiDuyet=0 AND ISNULL(mt.IDTrangThaiDuyet,0) = 1)
			OR (@IDTrangThaiDuyet=1 AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10))
			OR (@IDTrangThaiDuyet=2 AND ISNULL(mt.IDTrangThaiDuyet,0) in (3,6,9))
			OR (@IDTrangThaiDuyet=3 AND ISNULL(mt.IDTrangThaiDuyet,0) in (2,5,8))
		)
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY lmt.ThuTu, nmt.ThuTuCha, nmt.ThuTu, nmt.CapBac, nmt.IDNhomMucTieu, mt.MaThuMuc;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_HUY_DUYET_ThietLap_TrongSo]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[sp_HUY_DUYET_ThietLap_TrongSo]
@IDHTMT	bigint,
@IDHTTS	bigint,
@ChuThe tinyint,
@IDMucTieu bigint,
@IDCoCau bigint,
@IDNguoiPhuTrach bigint,
@TrongSo decimal(5, 2),
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	IF (@IDMucTieu>0)
	BEGIN
		UPDATE TW_MucTieuTrongSo 
		SET DaDuyet=0
		WHERE IDHTMT=@IDHTMT and IDHTTS=@IDHTTS and IDMucTieu=@IDMucTieu 
			AND (
					(ISNULL(@ChuThe,0) = 0 AND IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(IDCoCau,0)=@IDCoCau))
					OR 
					(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
				);
	END;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_HUY_KHOA_DanhGiaTongHop]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_HUY_KHOA_DanhGiaTongHop]
@IDDanhGia bigint,
@IDHTMT bigint,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Count int=0;

	Update TW_DanhGia set Khoa=0 WHERE IDDanhGia=@IDDanhGia;
	Update TW_DanhGiaTongHop set Khoa=0 WHERE IDDanhGia=@IDDanhGia;
	
	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_KHOA_DanhGiaTongHop]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_KHOA_DanhGiaTongHop]
@IDDanhGia bigint,
@IDHTMT bigint,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Count int=0;

	Update TW_DanhGia set Khoa=1 WHERE IDDanhGia=@IDDanhGia;
	Update TW_DanhGiaTongHop set Khoa=1 WHERE IDDanhGia=@IDDanhGia;
	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DanhGia]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_LAY_DanhGia]
@IDHTMT	bigint,
@IDHTTS	bigint,
@IDCoCau	bigint,
@IDNguoiPhuTrach	bigint,
@IDChucDanh bigint=null,
@IsDanhGia tinyint,
@IDNhanSu bigint
AS
BEGIN
	
	DECLARE @KyDanhGia nvarchar(50);
	SELECT @KyDanhGia=TenTanSuat FROM TW_HeThongTanSuat WHERE IDHTTS=@IDHTTS;
	DECLARE @ChuThe tinyint=0;
	IF ISNULL(@IDCoCau,0)=0 SELECT @ChuThe=1;

	DECLARE @CountKN int=0;
	IF ISNULL(@ChuThe,0) = 1
	BEGIN
		SELECT @CountKN=COUNT(*) 
		FROM TW_TyTrongChucDanh ttcd
		LEFT JOIN SYS_NhanSu ns on ns.IDChucDanh=ttcd.IDChucDanh and ns.IDNhanSu=ttcd.IDNhanSu
		WHERE ttcd.IDHTMT=@IDHTMT 
			and ttcd.IDHTTS=@IDHTTS 
			and ttcd.IDNhanSu=@IDNguoiPhuTrach 
			and ISNULL(ttcd.TyTrong,0)>0
			AND ns.IDNhanSu is null;--Không phải chức danh chính

		--Xoa bớt dánh giá kiêm nhiệm
		DELETE FROM TW_DanhGia 
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) 
		and IDChucDanh>0
		and (@CountKN=0
			 OR IDChucDanh IN (SELECT IDChucDanh FROM TW_TyTrongChucDanh  
							  WHERE IDHTMT=@IDHTMT 
							  and IDHTTS=@IDHTTS 
							  and IDNhanSu=@IDNguoiPhuTrach 
							  and ISNULL(TyTrong,0)=0--Chức danh tỷ trọng = 0 => không kiêm nhiệm
							)
			)
	END;

	SELECT TOP 1 dg.IDDanhGia,htmt.MaHTMT,htmt.TenHTMT,cc.MaCoCau, cc.TenCoCau, ns.HoVaTen, ns.MaNhanSu,cd.MaChucDanh,cd.TenChucDanh,
	(CASE WHEN @IsDanhGia=1 THEN dg.Diem ELSE dg.DiemTamTinh END) AS Diem,
	--dg.Diem,
	@KyDanhGia as KyDanhGia,ISNULL(ttcd.IsKiemNhiem,0) as IsKiemNhiem,
	mdg.MaMucDanhGia,
	mdg.MucDanhGia,
	mdg.MauSac
	FROM TW_DanhGia dg
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=dg.IDHTMT
	LEFT JOIN SYS_NhanSu ns on ns.IDNhanSu=dg.IDNguoiPhuTrach
	LEFT JOIN SYS_CoCau cc on (
								(ISNULL(@IDCoCau,0)>0 AND ISNULL(@IDCoCau,0)=cc.IDCoCau) 
								OR (ISNULL(@IDCoCau,0)=0 AND cc.IDCoCau=ns.IDCoCau)
							  )
	LEFT JOIN SYS_ChucDanh cd on (ISNULL(@IDChucDanh,0)=0 AND cd.IDChucDanh = ns.IDChucDanh) OR (ISNULL(@IDChucDanh,0)>0 AND cd.IDChucDanh = @IDChucDanh)
	LEFT JOIN TW_TyTrongChucDanh ttcd on ttcd.IDNhanSu=ns.IDNhanSu and ttcd.IDChucDanh=cd.IDChucDanh
	LEFT JOIN TW_MucDanhGia mdg on mdg.IDKhachHang=htmt.IDKhachHang and mdg.IDChuThe=@ChuThe and ISNULL(mdg.IsDelete,0)=0
		AND (
				(@IsDanhGia=1 AND dg.Diem > mdg.DiemTu AND dg.Diem <= mdg.DiemDen)
				OR
				(@IsDanhGia=0 AND dg.DiemTamTinh > mdg.DiemTu AND dg.DiemTamTinh <= mdg.DiemDen)
			)
	WHERE dg.IDHTMT=@IDHTMT AND dg.IDHTTS=@IDHTTS AND dg.IDCoCau=ISNULL(@IDCoCau,0) AND dg.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) 
	AND (@CountKN=0 AND dg.IDChucDanh=0
		OR
		@CountKN>0 AND dg.IDChucDanh=ISNULL(@IDChucDanh,0)
		)
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DanhGia_TongHop]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_LAY_DanhGia_TongHop]
@IDHTMT	bigint,
@IDHTTS	bigint,
@IDCoCau	bigint,
@IDNguoiPhuTrach	bigint,
@IsDanhGia tinyint,
@IDNhanSu bigint
AS
BEGIN
	
	DECLARE @KyDanhGia nvarchar(50);
	SELECT @KyDanhGia=TenTanSuat FROM TW_HeThongTanSuat WHERE IDHTTS=@IDHTTS;
	DECLARE @IDChuThe tinyint=0;
	IF ISNULL(@IDCoCau,0)=0 SELECT @IDChuThe=1;

	SELECT TOP 1 dg.IDDanhGia,htmt.MaHTMT,htmt.TenHTMT,cc.MaCoCau, cc.TenCoCau, ns.HoVaTen, ns.MaNhanSu,mdg.MucDanhGia, cd.MaChucDanh,cd.TenChucDanh,mdg.MauSac, @KyDanhGia as KyDanhGia,
	ISNULL(dgth.DiemDuyet,ISNULL(dg.TongDiem,dg.Diem)) as Diem,
	ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) as MaMucDanhGia
	FROM TW_DanhGia dg
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=dg.IDHTMT
	LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia
	LEFT JOIN SYS_NhanSu ns on ns.IDNhanSu=dg.IDNguoiPhuTrach
	LEFT JOIN SYS_CoCau cc on (
								(ISNULL(@IDCoCau,0)>0 AND ISNULL(@IDCoCau,0)=cc.IDCoCau) 
								OR (ISNULL(@IDCoCau,0)=0 AND cc.IDCoCau=ns.IDCoCau)
							  )
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh = ns.IDChucDanh
	LEFT JOIN TW_MucDanhGia mdg on mdg.IDKhachHang=htmt.IDKhachHang and mdg.IDChuThe=@IDChuThe and ISNULL(mdg.IsDelete,0)=0
		AND (
				(@IsDanhGia=1 AND mdg.MaMucDanhGia=ISNULL(dgth.MucDuyet,dg.MaMucDanhGia))
				OR
				(@IsDanhGia=0 AND mdg.MaMucDanhGia=ISNULL(dgth.MucDuyet,dg.MaMucTamTinh))
			)
	WHERE dg.IDHTMT=@IDHTMT AND dg.IDHTTS=@IDHTTS AND dg.IDCoCau=ISNULL(@IDCoCau,0) AND dg.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0);
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_CoCau]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_CoCau]
@IDNhomCap bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@CayThuMuc nvarchar(256);

	SELECT @Q_IDCoCau=IDCoCau FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		
	IF @IDQuyen=1
	INSERT INTO @TableID (id)
	SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and IDCoCau=@Q_IDCoCau;

	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;
	
	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT cc.IDCoCau,cc.MaCoCau,cc.TenCoCau,cc.CapBac
	FROM SYS_CoCau cc
	--Kiểm tra Quyền theo setting
	LEFT JOIN @TableID Q1 ON (@IDQuyen=5
		OR (@IDQuyen in (1,2,3,4) AND (cc.IDCoCau=Q1.id))
		)
	WHERE cc.SuDung=1
	AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
	AND cc.IDKhachHang=@IDKhachHang
	AND (@IDNhomCap Is null OR (@IDNhomCap is not null and cc.IDNhomCap = @IDNhomCap))
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(cc.IsDelete,0) = @IsDelete))
	ORDER BY CC.MaThuMuc,cc.MaCoCau
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_CoCauCon]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_CoCauCon]
@IDCoCauCha bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	DECLARE @CayThuMuc nvarchar(256);
	DECLARE @CapBac int;
	SELECT @CayThuMuc=CayThuMuc,@CapBac=CapBac FROM SYS_CoCau WHERE IDCoCau=@IDCoCauCha;

	SELECT cc.IDCoCau,cc.MaCoCau,cc.TenCoCau,cc.CapBac,ns.*
	FROM SYS_CoCau cc
	LEFT JOIN
		(SELECT ns.IDNhanSu,ns.MaNhanSu,ns.HoVaTen,ns.AnhNhanSu, cd.IDCoCau as IDCoCauNS,cd.IDChucDanh,cd.MaChucDanh,cd.TenChucDanh,ns.IDKhachHang, row_number() over (partition by cd.IDChucDanh order by cd.LaCapTruong desc) as STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
		WHERE ISNULL(ns.IsDelete,0)=0 and ISNULL(ns.TrangThai,0)=1
		AND ns.IDKhachHang=@IDKhachHang) ns 
			ON ns.IDCoCauNS=cc.IDCoCau and ns.IDKhachHang=cc.IDKhachHang and ns.STT=1
	WHERE cc.SuDung=1
	AND cc.IDKhachHang=@IDKhachHang
	AND (cc.CapBac=@CapBac OR cc.CapBac=@CapBac+1)
	AND cc.CayThuMuc like @CayThuMuc+'%'
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(cc.IsDelete,0) = @IsDelete))
	ORDER BY CC.MaThuMuc,cc.MaCoCau
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_DonViTinh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_DonViTinh]
@IDCha bigint=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	With tmp as
	(
	select x.IDKieuDuLieu as IDKieuDuLieu, cast(x.ThuTu * 1000 as nvarchar(256)) as STT, cast(0 as bigint) as IDDonViTinh, cast(x.TenKieuDuLieu as nvarchar(128)) as TenDonViTinh
		from ENUM_KieuDuLieu x
	union all 
	select dvt.IDKieuDuLieu as IDKieuDuLieu, cast(kdl.ThuTu * 1000 as nvarchar(256))+'_'+dvt.TenDonViTinh as STT, dvt.IDDonViTinh, dvt.TenDonViTinh
	from TW_DonViTinh dvt
	inner join ENUM_KieuDuLieu kdl on kdl.IDKieuDuLieu=dvt.IDKieuDuLieu
	and dvt.SuDung=1
	where dvt.IDKhachHang=@IDKhachHang AND ISNULL(IsDelete,0)=0
	)
	select * from tmp
	order by STT
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_HeThongMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_HeThongMucTieu]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	
	SELECT htmt.*
	FROM TW_HeThongMucTieu htmt
	WHERE IDKhachHang=@IDKhachHang AND ISNULL(htmt.SuDung,0)=1 
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(htmt.IsDelete,0) = @IsDelete))
	ORDER BY htmt.KetThuc DESC, htmt.MaHTMT
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_HeThongTanSuat]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_HeThongTanSuat]
@IDHTMT bigint=0,
@IDLoaiTanSuat tinyint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	SELECT htts.*
	FROM TW_HeThongMucTieu htmt
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTMT=htmt.IDHTMT
	WHERE htmt.IDKhachHang=@IDKhachHang AND ISNULL(htmt.SuDung,0)=1  AND ISNULL(htts.SuDung,0)=1 
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(htts.IsDelete,0) = @IsDelete and ISNULL(htmt.IsDelete,0) = @IsDelete))
	AND (@IDHTMT is null or (@IDHTMT is not null and ISNULL(htts.IDHTMT,0)=@IDHTMT))
	AND (@IDLoaiTanSuat is null or (@IDLoaiTanSuat is not null and htts.IDLoaiTanSuat=@IDLoaiTanSuat))
	ORDER BY htts.IDLoaiTanSuat, htts.BatDau, htts.TenTanSuat
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_KieuDuLieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_KieuDuLieu]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_KieuDuLieu
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_KyDuLieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_KyDuLieu]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_KyDuLieu
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_LoaiChiTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_LoaiChiTieu]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_LoaiChiTieu
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_LoaiMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_LoaiMucTieu]
@IDHTMT bigint=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT lmt.*
	FROM TW_LoaiMucTieu lmt
	WHERE IDHTMT=@IDHTMT AND ISNULL(lmt.SuDung,0)=1 AND ISNULL(IsDelete,0)=0
	ORDER BY lmt.ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_LoaiMucTieuTrucTiep]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_LoaiMucTieuTrucTiep]
@IDHTMT bigint=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT lmt.*
	FROM TW_LoaiMucTieu lmt
	WHERE IDHTMT=@IDHTMT AND ISNULL(lmt.SuDung,0)=1 AND ISNULL(IsDelete,0)=0 AND ISNULL(TinhTrucTiep,0)=1
	ORDER BY lmt.ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_LoaiTanSuat]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_LoaiTanSuat]
@IDHTMT int=0,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	SELECT *
	FROM ENUM_LoaiTanSuat
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_MucDanhGia]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_MucDanhGia]
@IDChuThe tinyint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	SELECT *
	FROM TW_MucDanhGia
	WHERE IDKhachHang=@IDKhachHang AND ISNULL(IsDelete,0)=0
	AND (
		 (@IDChuThe IS NULL) 
		 OR 
		 (@IDChuThe IS NOT NULL AND	IDChuThe=@IDChuThe)
		)
	ORDER BY DiemDen desc, MaMucDanhGia
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_MucUuTien]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_MucUuTien]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_MucUuTien
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_NamTaiChinh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_NamTaiChinh]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	SELECT *
	FROM TW_NamTaiChinh
	WHERE IDKhachHang=@IDKhachHang
	AND ISNULL(IsDelete,0)=0
	ORDER BY Nam
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_NhanSu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_NhanSu]
@IDNhomCap tinyint=null,
@IDCha bigint=null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	SELECT ns.*
	FROM SYS_NhanSu ns
	INNER JOIN SYS_CoCau cc on cc.IDCoCau=ns.IDCoCau
	WHERE ns.IDKhachHang=@IDKhachHang AND ns.TrangThai=1 
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(ns.IsDelete,0) = @IsDelete))
	ORDER BY ns.MaNhanSu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_NhomCap]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_NhomCap]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT nc.*
	FROM TW_NhomCap nc
	WHERE IDKhachHang=@IDKhachHang AND nc.SuDung=1 AND ISNULL(IsDelete,0)=0
	ORDER BY nc.ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_NhomMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_NhomMucTieu]
@IDHTMT bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	With tmp as
	(
		select lmt.IDLoaiMucTieu, 0 as IDNhomMucTieu, '' as MaNhomMucTieu, 1 as CapBac,cast(lmt.TenLoaiMucTieu as nvarchar(256)) as TenNhomMucTieu, cast(FORMAT(lmt.ThuTu,'d10') as varchar(50))+'_'+cast(FORMAT(lmt.IDLoaiMucTieu,'d10') as varchar(50)) as STT
		from TW_LoaiMucTieu lmt
		inner join TW_HeThongMucTieu htmt on htmt.IDHTMT=@IDHTMT and htmt.IDKhachHang=@IDKhachHang
		where lmt.IDHTMT=@IDHTMT AND ISNULL(lmt.SuDung,0)=1
	union all 
	select lmt.IDLoaiMucTieu, nmt.IDNhomMucTieu as IDNhomMucTieu, nmt.MaNhomMucTieu as MaNhomMucTieu, nmt.CapBac,cast(nmt.TenNhomMucTieu as nvarchar(256)) as TenNhomMucTieu, cast(FORMAT(lmt.ThuTu,'d10') as varchar(50))+'_'+cast(FORMAT(lmt.IDLoaiMucTieu,'d10') as varchar(50))+'_'+cast(FORMAT(nmt.ThuTuCha,'d10') as varchar(50))+'_'+cast(FORMAT(nmt.ThuTu,'d10') as varchar(50)) as STT
	from TW_LoaiMucTieu lmt
	inner join TW_NhomMucTieu nmt on nmt.IDLoaiMucTieu=lmt.IDLoaiMucTieu and nmt.IDHTMT=@IDHTMT
	inner join TW_HeThongMucTieu htmt on htmt.IDHTMT=@IDHTMT and htmt.IDKhachHang=@IDKhachHang
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(nmt.IsDelete,0) = @IsDelete))
	AND ISNULL(nmt.SuDung,0)=1
	where lmt.IDHTMT=@IDHTMT
	)
	select * from tmp
	order by STT
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_NhomMucTieuCha]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_NhomMucTieuCha]
@IDHTMT bigint,
@IDLoaiMucTieu tinyint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	
	SELECT nmt.IDNhomMucTieu,nmt.MaNhomMucTieu,nmt.TenNhomMucTieu,nmt.CapBac
	FROM TW_NhomMucTieu nmt
	WHERE IDHTMT=@IDHTMT
	AND IDLoaiMucTieu=@IDLoaiMucTieu
	AND ISNULL(nmt.SuDung,0)=1
	AND ISNULL(IDCha,0)=0
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(nmt.IsDelete,0) = @IsDelete))
	ORDER BY nmt.ThuTuCha, nmt.ThuTu;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_QuyenChung]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_QuyenChung]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_QuyenChung
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_QuyenDuyet]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_QuyenDuyet]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_QuyenDuyet
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_QuyenDuyetCap]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_QuyenDuyetCap]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_QuyenDuyetCap
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_QuyenNhap]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_QuyenNhap]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_QuyenNhap
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_TrangThaiMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_TrangThaiMucTieu]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_TrangThaiMucTieu
	WHERE SuDung=1
	ORDER BY ThuTu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DDL_TrangThaiNhanSu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DDL_TrangThaiNhanSu]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT *
	FROM ENUM_TrangThaiNhanSu
	WHERE SuDung=1
	ORDER BY ThuTu
END

GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DLL_ChucDanhNhanSu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DLL_ChucDanhNhanSu]
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	--SELECT cd.IDChucDanh,cd.MaChucDanh,cd.TenChucDanh,cc.TenCoCau,'0' as KiemNhiem
	--FROM SYS_NhanSu ns
	--INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh
	--LEFT JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
	--WHERE ns.IDNhanSu=@IDNhanSu and ISNULL(cd.IsDelete,0)=0
	--Union all
	--SELECT cd.IDChucDanh,cd.MaChucDanh,cd.TenChucDanh,cc.TenCoCau,'1' as KiemNhiem
	--FROM SYS_NhanSu ns
	--LEFT JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
	--LEFT JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
	--LEFT JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
	--WHERE ns.IDNhanSu=@IDNhanSu and ISNULL(cd.IsDelete,0)=0
	--ORDER BY cd.MaChucDanh;

	with Data_CTE as 
	(SELECT cd.IDChucDanh,cd.MaChucDanh,cd.TenChucDanh,cc.TenCoCau,'0' as KiemNhiem
	FROM SYS_NhanSu ns
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu and ISNULL(cd.IsDelete,0)=0
	Union 
	SELECT cd.IDChucDanh,cd.MaChucDanh,cd.TenChucDanh,cc.TenCoCau,'1' as KiemNhiem
	FROM SYS_NhanSu ns
	LEFT JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
	LEFT JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu and ISNULL(cd.IsDelete,0)=0
	)
	select * from Data_CTE
	where IDChucDanh is not null
	order by KiemNhiem,MaChucDanh;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DLL_ChucDanhSearch]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DLL_ChucDanhSearch]
@IDCoCau bigint=null,
@IDNhomCap tinyint=null,
@IDCha bigint=null,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	--with Data_CTE as 
	--(
	--  select x.IDKhachHang, x.IDCoCau, x.STT, x.CapBac,x.MaCoCau,x.TenCoCau
	--  from SYS_CoCau x 
	--  where x.IDKhachHang=@IDKhachHang
	--  AND ISNULL(x.IsDelete,0) = 0
	--  AND ((ISNULL(@IDCha,0) = 0 and ISNULL(x.IDCha,0)=0) or (ISNULL(@IDCha,0) > 0 and x.IDCoCau=@IDCha))
	--	union all 
	--  select x.IDKhachHang, x.IDCoCau, x.STT, x.CapBac,x.MaCoCau,x.TenCoCau
	--  from SYS_CoCau x inner join Data_CTE on x.IDCha = Data_CTE.IDCoCau
	--  AND ISNULL(x.IsDelete,0) = 0
	--  AND x.IDKhachHang=@IDKhachHang
	--)
	SELECT cd.IDChucDanh, cc.CapBac AS CapBacCoCau,cc.MaCoCau, cd.MaChucDanh, cd.TenChucDanh, cc.TenCoCau
	FROM SYS_CoCau cc
	INNER JOIN SYS_ChucDanh cd on cc.IDCoCau = cd.IDCoCau and cd.IDKhachHang=cc.IDKhachHang
	WHERE ISNULL(cd.IsDelete,0) = 0
	AND cc.IDKhachHang=@IDKhachHang
	AND (@IDCoCau is null or (@IDCoCau is not null and cd.IDCoCau=@IDCoCau))
	AND (@Keyword is null or (@Keyword is not null and lower(cc.MaCoCau) + ' ' + lower(cc.TenCoCau)  + ' ' + lower(cd.MaChucDanh) + ' ' + lower(cd.TenChucDanh) like '%' + lower(@Keyword) + '%'))
	ORDER BY cc.MaThuMuc, cd.MaChucDanh;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DLL_MucTieuSearch]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DLL_MucTieuSearch]
@IDHTMT	bigint =null,
@IDNhomCap tinyint=null,
@IDNhomMucTieu bigint,
@IDMucTieu bigint=null,
@IDCha bigint=null,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	SELECT TOP 30 mt.IDMucTieu,mt.MaMucTieu, mt.TenMucTieu,mt.CapBac
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	WHERE ISNULL(mt.IsDelete,0) = 0 
	AND htmt.IDKhachHang=@IDKhachHang
	AND (@IDHTMT is null or (@IDHTMT is not null and mt.IDHTMT=@IDHTMT))
	--AND (@IDNhomCap is null or (@IDNhomCap is not null and mt.IDNhomCap=@IDNhomCap))
	AND (@IDNhomMucTieu is null or (@IDNhomMucTieu is not null and mt.IDNhomMucTieu=@IDNhomMucTieu))
	AND (@IDMucTieu is null or (@IDMucTieu is not null and mt.IDMucTieu!=@IDMucTieu))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DLL_NhanSuSearch]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DLL_NhanSuSearch]
@ListID NVARCHAR(1000),
@IDCha bigint=null,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	IF(@ListID is not null)
	BEGIN
		DECLARE @ArrID TABLE(id bigint NOT NULL);
		INSERT INTO @ArrID values(cast(@ListID as bigint));
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	DECLARE @TOP int=30;
	if(@ListID IS NOT NULL) SELECT @TOP=100;
	SELECT TOP (@TOP)  ns.IDNhanSu,ns.HoVaTen,ns.MaNhanSu,ns.TenNhanSuNgan,ns.IDChucDanh,ns.IDCoCau,ns.AnhNhanSu, cc.CapBac AS CapBacCoCau,cc.MaCoCau, cd.MaChucDanh, cd.TenChucDanh, cc.TenCoCau
	FROM SYS_NhanSu ns
	INNER JOIN SYS_CoCau cc on ns.IDCoCau = cc.IDCoCau and ns.IDKhachHang=cc.IDKhachHang
	LEFT JOIN SYS_ChucDanh cd on ns.IDChucDanh=cd.IDChucDanh and ns.IDCoCau=cc.IDCoCau
	WHERE ns.TrangThai=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(ns.IDNhanSu=@IDNhanSu
					OR
					(
						(@IDQuyen=1 AND ns.IDNhanSu in (select id from @TableID))
						OR (@IDQuyen in (2,3) AND (ns.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
						OR (@IDQuyen=4 AND (cc.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND (@ListID IS NULL OR (@ListID IS NOT NULL and ns.IDCoCau in (select id from @ArrID)))
	AND ISNULL(ns.IsDelete,0) = 0
	AND ISNULL(cd.IsDelete,0) = 0
	AND ISNULL(cc.IsDelete,0) = 0
	AND ns.IDKhachHang=@IDKhachHang
	AND (@Keyword is null or (@Keyword is not null and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) + ' ' + lower(cd.MaChucDanh) + ' ' + lower(cd.TenChucDanh)like '%' + lower(@Keyword) + '%'));
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DLL_NhanSuSearch_AllChucDanh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DLL_NhanSuSearch_AllChucDanh]
@ListID NVARCHAR(1000),
@IDCha bigint=null,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @TOP int=30;

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	IF(@ListID is not null)
	BEGIN
		DECLARE @ArrID TABLE(id bigint NOT NULL);
		INSERT INTO @ArrID values(cast(@ListID as bigint));
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	DECLARE @TableNhanSu TABLE(IDNhanSu bigint NOT NULL, IDChucDanh bigint,ChucDanhChinh bit);

	INSERT INTO @TableNhanSu (IDNhanSu,IDChucDanh,ChucDanhChinh)
	SELECT TOP (@TOP) ns.IDNhanSu,cd.IDChucDanh,1
	FROM SYS_NhanSu ns
	INNER JOIN SYS_CoCau cc on ns.IDCoCau = cc.IDCoCau and ns.IDKhachHang=cc.IDKhachHang
	INNER JOIN SYS_ChucDanh cd on ns.IDChucDanh=cd.IDChucDanh and ns.IDCoCau=cc.IDCoCau
	WHERE ns.TrangThai=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(ns.IDNhanSu=@IDNhanSu
					OR
					(
						(@IDQuyen=1 AND ns.IDNhanSu in (select id from @TableID))
						OR (@IDQuyen in (2,3) AND (ns.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
						OR (@IDQuyen=4 AND (cc.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND (@ListID IS NULL OR (@ListID IS NOT NULL and ns.IDCoCau in (select id from @ArrID)))
	AND ISNULL(ns.IsDelete,0) = 0
	AND ISNULL(cd.IsDelete,0) = 0
	AND ISNULL(cc.IsDelete,0) = 0
	AND ns.IDKhachHang=@IDKhachHang
	AND (@Keyword is null or (@Keyword is not null and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) + ' ' + lower(cd.MaChucDanh) + ' ' + lower(cd.TenChucDanh)like '%' + lower(@Keyword) + '%'));


	INSERT INTO @TableNhanSu (IDNhanSu,IDChucDanh,ChucDanhChinh)
	SELECT TOP (@TOP) ns.IDNhanSu,cd.IDChucDanh,0
	FROM SYS_KiemNhiem kn
	INNER JOIN SYS_NhanSu ns on ns.DB_IDNhanSu=kn.DB_IDNhanSu
	INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
	INNER JOIN SYS_CoCau cc on cc.IDCoCau = cd.IDCoCau and cc.IDKhachHang=ns.IDKhachHang
	WHERE ns.TrangThai=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(ns.IDNhanSu=@IDNhanSu
					OR
					(
						(@IDQuyen=1 AND ns.IDNhanSu in (select id from @TableID))
						OR (@IDQuyen in (2,3) AND (ns.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
						OR (@IDQuyen=4 AND (cc.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND (@ListID IS NULL OR (@ListID IS NOT NULL and ns.IDCoCau in (select id from @ArrID)))
	AND ISNULL(ns.IsDelete,0) = 0
	AND ISNULL(cd.IsDelete,0) = 0
	AND ISNULL(cc.IsDelete,0) = 0
	AND ns.IDKhachHang=@IDKhachHang
	AND (@Keyword is null or (@Keyword is not null and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) + ' ' + lower(cd.MaChucDanh) + ' ' + lower(cd.TenChucDanh)like '%' + lower(@Keyword) + '%'));

	SELECT ns.IDNhanSu,ns.HoVaTen,ns.MaNhanSu,ns.TenNhanSuNgan,ns.AnhNhanSu, cc.CapBac AS CapBacCoCau,cc.MaCoCau, cd.IDChucDanh,cc.IDCoCau,cd.MaChucDanh,tmpNs.ChucDanhChinh, cd.TenChucDanh, cc.TenCoCau
	FROM @TableNhanSu tmpNS
	INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=tmpNS.IDNhanSu
	INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=tmpNS.IDChucDanh
	INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
	ORDER BY ns.HoVaTen,ns.IDNhanSu;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DLL_NhanSuSearchAdvance]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DLL_NhanSuSearchAdvance]
@ListID NVARCHAR(1000),
@IDCocau bigint,
@IDChucDanh bigint,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	IF(@ListID is not null)
	BEGIN
		DECLARE @ArrID TABLE(id bigint NOT NULL);
		INSERT INTO @ArrID values(cast(@ListID as bigint));
	END;
	
	DECLARE @TOP int=10000;
	if(@ListID IS NOT NULL) SELECT @TOP=500;

	With tmp as
	(SELECT TOP (@TOP)  ns.IDNhanSu,ns.HoVaTen,ns.MaNhanSu,ns.TenNhanSuNgan,cd.IDChucDanh,cc.IDCoCau,ns.AnhNhanSu, cc.CapBac AS CapBacCoCau,cc.MaCoCau, cd.MaChucDanh, cd.TenChucDanh, cc.TenCoCau, CAST (1 AS bit) as ChucDanhChinh
	FROM SYS_NhanSu ns
	INNER JOIN SYS_CoCau cc on ns.IDCoCau = cc.IDCoCau and ns.IDKhachHang=cc.IDKhachHang
	LEFT JOIN SYS_ChucDanh cd on ns.IDChucDanh=cd.IDChucDanh and ns.IDCoCau=cc.IDCoCau
	WHERE ns.TrangThai=1
	AND (@ListID IS NULL OR (@ListID IS NOT NULL and ns.IDCoCau in (select id from @ArrID)))
	AND ISNULL(ns.IsDelete,0) = 0
	AND cc.IDKhachHang=@IDKhachHang
	AND (@IDCocau is null or (@IDCocau is not null and cc.IDCoCau=@IDCocau))
	AND (@IDChucDanh is null or (@IDChucDanh is not null and ns.IDChucDanh=@IDChucDanh))
	AND (@Keyword is null or (@Keyword is not null and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) + ' ' + lower(cd.MaChucDanh) + ' ' + lower(cd.TenChucDanh)like '%' + lower(@Keyword) + '%'))
	UNION ALL
	SELECT TOP (@TOP)  ns.IDNhanSu,ns.HoVaTen,ns.MaNhanSu,ns.TenNhanSuNgan,cd.IDChucDanh,cc.IDCoCau,ns.AnhNhanSu, cc.CapBac AS CapBacCoCau,cc.MaCoCau, cd.MaChucDanh, cd.TenChucDanh, cc.TenCoCau, CAST (0 AS bit) as ChucDanhChinh
	FROM SYS_NhanSu ns
	INNER JOIN SYS_KiemNhiem kn on ns.DB_IDNhanSu=kn.DB_IDNhanSu
	INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
	INNER JOIN SYS_CoCau cc on cc.IDCoCau = cd.IDCoCau and ns.IDKhachHang=cc.IDKhachHang
	WHERE ns.TrangThai=1
	AND (@ListID IS NULL OR (@ListID IS NOT NULL and ns.IDCoCau in (select id from @ArrID)))
	AND ISNULL(ns.IsDelete,0) = 0
	AND cc.IDKhachHang=@IDKhachHang
	AND (@IDCocau is null or (@IDCocau is not null and cc.IDCoCau=@IDCocau))
	AND (@IDChucDanh is null or (@IDChucDanh is not null and cd.IDChucDanh=@IDChucDanh))
	AND (@Keyword is null or (@Keyword is not null and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) + ' ' + lower(cd.MaChucDanh) + ' ' + lower(cd.TenChucDanh)like '%' + lower(@Keyword) + '%'))
	)
	select * from tmp
	ORDER by MaNhanSu,MaChucDanh,MaCoCau
	;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DLL_NhanSuSearchFull]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DLL_NhanSuSearchFull]
@ListID NVARCHAR(1000),
@IDCha bigint=null,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	IF(@ListID is not null)
	BEGIN
		DECLARE @ArrID TABLE(id bigint NOT NULL);
		INSERT INTO @ArrID values(cast(@ListID as bigint));
	END;

	DECLARE @TOP int=30;
	if(@ListID IS NOT NULL) SELECT @TOP=100;
	SELECT TOP (@TOP)  ns.IDNhanSu,ns.HoVaTen,ns.MaNhanSu,ns.TenNhanSuNgan,ns.IDChucDanh,ns.IDCoCau,ns.AnhNhanSu, cc.CapBac AS CapBacCoCau,cc.MaCoCau, cd.MaChucDanh, cd.TenChucDanh, cc.TenCoCau
	FROM SYS_NhanSu ns
	INNER JOIN SYS_CoCau cc on ns.IDCoCau = cc.IDCoCau and ns.IDKhachHang=cc.IDKhachHang
	LEFT JOIN SYS_ChucDanh cd on ns.IDChucDanh=cd.IDChucDanh and ns.IDCoCau=cc.IDCoCau
	WHERE ns.TrangThai=1
	AND (@ListID IS NULL OR (@ListID IS NOT NULL and ns.IDCoCau in (select id from @ArrID)))
	AND ISNULL(ns.IsDelete,0) = 0
	AND ISNULL(cd.IsDelete,0) = 0
	AND ISNULL(cc.IsDelete,0) = 0
	AND ns.IDKhachHang=@IDKhachHang
	AND (@Keyword is null or (@Keyword is not null and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) + ' ' + lower(cd.MaChucDanh) + ' ' + lower(cd.TenChucDanh)like '%' + lower(@Keyword) + '%'));
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DS_IDCoCau]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DS_IDCoCau]
@IDNhomCap bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@CayThuMuc nvarchar(256);

	SELECT @Q_IDCoCau=IDCoCau FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		
	IF @IDQuyen=1
	INSERT INTO @TableID (id)
	SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and IDCoCau=@Q_IDCoCau;

	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;
	
	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT cc.IDCoCau as ID
	FROM SYS_CoCau cc
	--Kiểm tra Quyền theo setting
	LEFT JOIN @TableID Q1 ON (@IDQuyen=5
		OR (@IDQuyen in (1,2,3,4) AND (cc.IDCoCau=Q1.id))
		)
	WHERE cc.SuDung=1
	AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
	AND cc.IDKhachHang=@IDKhachHang
	AND (@IDNhomCap Is null OR (@IDNhomCap is not null and cc.IDNhomCap = @IDNhomCap))
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(cc.IsDelete,0) = @IsDelete))
	ORDER BY CC.MaThuMuc,cc.MaCoCau
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DS_IDNhanSu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DS_IDNhanSu]
@ListID NVARCHAR(1000),
@IDCha bigint=null,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	IF(@ListID is not null)
	BEGIN
		DECLARE @ArrID TABLE(id bigint NOT NULL);
		INSERT INTO @ArrID values(cast(@ListID as bigint));
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	SELECT ns.IDNhanSu as ID
	FROM SYS_NhanSu ns
	INNER JOIN SYS_CoCau cc on ns.IDCoCau = cc.IDCoCau and ns.IDKhachHang=cc.IDKhachHang
	LEFT JOIN SYS_ChucDanh cd on ns.IDChucDanh=cd.IDChucDanh and ns.IDCoCau=cc.IDCoCau
	WHERE ns.TrangThai=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(ns.IDNhanSu=@IDNhanSu
					OR
					(
						(@IDQuyen=1 AND ns.IDNhanSu in (select id from @TableID))
						OR (@IDQuyen in (2,3) AND (ns.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
						OR (@IDQuyen=4 AND (cc.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND (@ListID IS NULL OR (@ListID IS NOT NULL and ns.IDCoCau in (select id from @ArrID)))
	AND ISNULL(ns.IsDelete,0) = 0
	AND ISNULL(cd.IsDelete,0) = 0
	AND ISNULL(cc.IsDelete,0) = 0
	AND ns.IDKhachHang=@IDKhachHang;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSCanhBao]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_LAY_DSCanhBao]
@IDNhanSu bigint,
@IDKhachHang int
AS
BEGIN
	DECLARE @Date datetime;
	SELECT @Date=MAX(CreatedDate) FROM TW_CanhBao WHERE IDNguoiPhuTrach=@IDNhanSu;
	
	DECLARE @IDCoCau bigint;
	SELECT @IDCoCau=ns.IDCoCau 
	FROM SYS_NhanSu ns
	INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh
	WHERE ns.IDNhanSu=@IDNhanSu
	and ISNULL(cd.LaCapTruong,0)=1;

	SELECT TOP 20 cb.IDHTMT,cb.IDHTTS,cb.IDDanhGia,cb.IDNguoiPhuTrach,
	cb.IDLoaiCanhBao,
	cb.SoLuong,cb.IsXem,
	htmt.MaHTMT,HTMT.TenHTMT,HTTS.TenTanSuat,cc.TenCoCau,
	FORMAT(cb.CreatedDate, 'yyyy-MM-dd') as sCreatedDate
	FROM TW_CanhBao cb
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=cb.IDHTMT
	INNER JOIN TW_HeThongTanSuat HTTS on HTTS.IDHTTS=cb.IDHTTS
	LEFT JOIN TW_DanhGia DG on DG.IDDanhGia=cb.IDDanhGia
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=DG.IDCoCau
	WHERE cb.CreatedDate=@Date
	AND (cb.IDNguoiPhuTrach=@IDNhanSu
		OR (@IDCoCau IS NOT NULL and dg.IDCoCau=@IDCoCau)
		)
	ORDER BY cb.CreatedDate desc, cb.IDNguoiPhuTrach,htmt.MaHTMT,htts.BatDau,htts.KetThuc

END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSCanhBaoAll]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_LAY_DSCanhBaoAll]
@IDKhachHang int
AS
BEGIN
	DECLARE @Date datetime;
	SELECT @Date=MAX(cb.CreatedDate) 
	FROM TW_CanhBao cb 
	INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=cb.IDNguoiPhuTrach
	WHERE ns.IDKhachHang=@IDKhachHang;
	
	SELECT cb.IDHTMT,cb.IDHTTS,cb.IDDanhGia,cb.IDNguoiPhuTrach,
	cb.IDLoaiCanhBao,
	cb.SoLuong,cb.IsXem,
	htmt.MaHTMT,HTMT.TenHTMT,HTTS.TenTanSuat,cc.TenCoCau,
	FORMAT(cb.CreatedDate, 'yyyy-MM-dd') as sCreatedDate
	FROM TW_CanhBao cb
	INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=cb.IDNguoiPhuTrach
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=cb.IDHTMT
	INNER JOIN TW_HeThongTanSuat HTTS on HTTS.IDHTTS=cb.IDHTTS
	LEFT JOIN TW_DanhGia DG on DG.IDDanhGia=cb.IDDanhGia
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=DG.IDCoCau
	WHERE cb.CreatedDate=@Date
	AND ns.IDKhachHang=@IDKhachHang
	ORDER BY cb.IDNguoiPhuTrach, htmt.MaHTMT,htts.BatDau,htts.KetThuc

END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSChucDanh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSChucDanh]
@IDCha bigint=null,
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@Q_IDChucDanh);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	DECLARE @TotalRow int;
	
	SELECT @TotalRow=COUNT(*)
	FROM SYS_ChucDanh cd
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau and cc.IDKhachHang=cd.IDKhachHang
	--Kiểm tra Quyền theo setting
	LEFT JOIN @TableID Q1 ON (@IDQuyen=5
		OR (@IDQuyen=1 AND cd.IDChucDanh=Q1.id)
		OR (@IDQuyen in (2,3,4) AND (cd.IDCoCau=Q1.id))
		)
	WHERE cd.IDKhachHang=@IDKhachHang
	AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(cd.IsDelete,0) = @IsDelete))
	AND (@Keyword is null or (@Keyword is not null and lower(cd.MaChucDanh) + ' ' + lower(cd.TenChucDanh) like '%' + lower(@Keyword) + '%'))
	AND (@IDCha Is null OR (@IDCha is not null and cc.CayThuMuc like '%;' + cast(@IDCha as varchar(20)) + ';%'));

	SELECT cd.*,cc.MaCoCau,cc.TenCoCau,cc.CapBac as CapBacCoCau, @TotalRow as TotalRow
	FROM SYS_ChucDanh cd
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau and cc.IDKhachHang=cd.IDKhachHang
	--Kiểm tra Quyền theo setting
	LEFT JOIN @TableID Q1 ON (@IDQuyen=5
		OR (@IDQuyen=1 AND cd.IDChucDanh=Q1.id)
		OR (@IDQuyen in (2,3,4) AND (cd.IDCoCau=Q1.id))
		)
	WHERE cd.IDKhachHang=@IDKhachHang
	AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(cd.IsDelete,0) = @IsDelete))
	AND (@Keyword is null or (@Keyword is not null and lower(cd.MaChucDanh) + ' ' + lower(cd.TenChucDanh) like '%' + lower(@Keyword) + '%'))
	AND (@IDCha Is null OR (@IDCha is not null and cc.CayThuMuc like '%;' + cast(@IDCha as varchar(20)) + ';%'))
	ORDER BY cd.MaThuMuc,cc.MaThuMuc
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSCoCau]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSCoCau]
@IDNhomCap tinyint=null,
@IDCha bigint=null,
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@Q_IDCoCau);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	DECLARE @TotalRow int;

	SELECT @TotalRow=COUNT(*)
	from SYS_CoCau cc 
	--Kiểm tra Quyền theo setting
	LEFT JOIN @TableID Q1 ON (@IDQuyen=5
		OR (@IDQuyen in (1,2,3,4) AND (cc.IDCoCau=Q1.id))
		)
	WHERE cc.IDKhachHang=@IDKhachHang
	AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
	AND (@IDNhomCap Is null OR (@IDNhomCap is not null and cc.IDNhomCap=@IDNhomCap))
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(cc.IsDelete,0) = @IsDelete))
	AND (@Keyword is null or (@Keyword is not null and lower(cc.MaCoCau) + ' ' + lower(cc.TenCoCau) like '%' + lower(@Keyword) + '%'))
	AND (@IDCha Is null OR (@IDCha is not null and cc.CayThuMuc like '%;' + cast(@IDCha as varchar(20)) + ';%'));

	SELECT cc.*,nc.TenNhomCap, @TotalRow as TotalRow
	from SYS_CoCau cc 
	LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=cc.IDNhomCap
	--Kiểm tra Quyền theo setting
	LEFT JOIN @TableID Q1 ON (@IDQuyen=5
		OR (@IDQuyen in (1,2,3,4) AND (cc.IDCoCau=Q1.id))
		)
	WHERE cc.IDKhachHang=@IDKhachHang
	AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
	AND (@IDNhomCap Is null OR (@IDNhomCap is not null and cc.IDNhomCap=@IDNhomCap))
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(cc.IsDelete,0) = @IsDelete))
	AND (@Keyword is null or (@Keyword is not null and lower(cc.MaCoCau) + ' ' + lower(cc.TenCoCau) like '%' + lower(@Keyword) + '%'))
	AND (@IDCha Is null OR (@IDCha is not null and cc.CayThuMuc like '%;' + cast(@IDCha as varchar(20)) + ';%'))
	ORDER BY cc.MaThuMuc,cc.MaCoCau
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSDonViTinh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSDonViTinh]
@IDKieuDuLieu tinyint=null,
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	With Count_CTE 
	AS 
	(
		SELECT COUNT(*) AS TotalRow 
		FROM TW_DonViTinh dvt
		WHERE dvt.IDKhachHang=@IDKhachHang
		AND (@IDKieuDuLieu is null or (@IDKieuDuLieu is not null and dvt.IDKieuDuLieu=@IDKieuDuLieu))
		AND (@SuDung is null or (@SuDung is not null and dvt.SuDung=@SuDung))
		AND ISNULL(dvt.IsDelete,0)=0
	)
	SELECT dvt.*,Count_CTE.TotalRow,kdl.TenKieuDuLieu
	FROM TW_DonViTinh dvt
	CROSS JOIN Count_CTE
	INNER JOIN ENUM_KieuDuLieu kdl on kdl.IDKieuDuLieu=dvt.IDKieuDuLieu
	WHERE dvt.IDKhachHang=@IDKhachHang
	AND (@IDKieuDuLieu is null or (@IDKieuDuLieu is not null and dvt.IDKieuDuLieu=@IDKieuDuLieu))
	AND (@SuDung is null or (@SuDung is not null and dvt.SuDung=@SuDung))
	AND ISNULL(dvt.IsDelete,0)=0
	ORDER BY kdl.ThuTu,dvt.TenDonViTinh
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSHeThongMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSHeThongMucTieu]
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	With Count_CTE 
	AS 
	(
		SELECT COUNT(*) AS TotalRow FROM TW_HeThongMucTieu
		WHERE IDKhachHang=@IDKhachHang
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(IsDelete,0) = @IsDelete))
		AND (@SuDung is null or (@SuDung is not null and SuDung=@SuDung))
	)
	SELECT htmt.*,Count_CTE.TotalRow, convert(varchar, htmt.BatDau, 103) as sBatDau, convert(varchar, htmt.KetThuc, 103) as sKetThuc, NTC.Nam
	FROM TW_HeThongMucTieu htmt
	LEFT JOIN TW_NamTaiChinh NTC on NTC.ID=htmt.IDNamTaiChinh and NTC.IDKhachHang=htmt.IDKhachHang
	CROSS JOIN Count_CTE
	WHERE htmt.IDKhachHang=@IDKhachHang
	AND (@SuDung is null or (@SuDung is not null and htmt.SuDung=@SuDung))
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(htmt.IsDelete,0) = @IsDelete))
	ORDER BY htmt.KetThuc DESC, htmt.MaHTMT
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSHeThongTanSuat]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSHeThongTanSuat]
@IDHTMT bigint,
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	With Count_CTE 
	AS 
	(
		SELECT COUNT(*) AS TotalRow 
		FROM TW_HeThongMucTieu htmt
		INNER JOIN TW_HeThongTanSuat htts on htts.IDHTMT=htmt.IDHTMT
		WHERE htmt.IDKhachHang=@IDKhachHang
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(htmt.IsDelete,0) = @IsDelete AND ISNULL(htts.IsDelete,0) = @IsDelete))
		AND (@IDHTMT is null or (@IDHTMT is not null and htts.IDHTMT=@IDHTMT))
		AND (@SuDung is null or (@SuDung is not null and htts.SuDung=@SuDung))
	)
	SELECT htts.*,Count_CTE.TotalRow, convert(varchar, htts.BatDau, 103) as sBatDau, convert(varchar, htts.KetThuc, 103) as sKetThuc, htmt.MaHTMT, ts.TenLoaiTanSuat
	FROM TW_HeThongMucTieu htmt
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTMT=htmt.IDHTMT
	INNER JOIN ENUM_LoaiTanSuat ts on ts.IDLoaiTanSuat=htts.IDLoaiTanSuat
	CROSS JOIN Count_CTE
	WHERE htmt.IDKhachHang=@IDKhachHang
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(htmt.IsDelete,0) = @IsDelete AND ISNULL(htts.IsDelete,0) = @IsDelete))
	AND (@IDHTMT is null or (@IDHTMT is not null and htts.IDHTMT=@IDHTMT))
	AND (@SuDung is null or (@SuDung is not null and htts.SuDung=@SuDung))
	ORDER BY htmt.BatDau DESC, htmt.MaHTMT, ts.ThuTu, htts.BatDau, htts.TenTanSuat
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSHeThongTanSuatChiTieuCon]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSHeThongTanSuatChiTieuCon]
@IDHTMT bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	select htts.*,lts.TenLoaiTanSuat
	from TW_HeThongTanSuat htts
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=htts.IDHTMT
	INNER JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=htts.IDLoaiTanSuat
	WHERE htts.IDHTMT=@IDHTMT
	AND htmt.IDKhachHang=@IDKhachHang
	AND htts.SuDung=1
	AND ISNULL(htts.IsDelete,0)=0
	AND htts.IDLoaiTanSuat>1--không lấy Tần suất Năm
	ORDER BY lts.ThuTu, htts.BatDau, htts.TenTanSuat;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSKhachHang]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_LAY_DSKhachHang]
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@Isdeleted bit,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	With Count_CTE 
	AS 
	(
		SELECT COUNT(*) AS TotalRow FROM SYS_KhachHang
		WHERE (Isdeleted IS NULL OR ISNULL(Isdeleted,0)=Isdeleted)
		AND ((Code like '%'+@Keyword+'%') OR (Name like '%'+@Keyword+'%') OR (Email like '%'+@Keyword+'%'))
	)
	SELECT kh.*, Count_CTE.TotalRow
	FROM SYS_KhachHang kh
	CROSS JOIN Count_CTE
	WHERE (Isdeleted IS NULL OR ISNULL(Isdeleted,0)=Isdeleted)
	AND ((Code like '%'+@Keyword+'%') OR (Name like '%'+@Keyword+'%') OR (Email like '%'+@Keyword+'%'))
	ORDER BY kh.Code
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSLoaiMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSLoaiMucTieu]
@IDHTMT bigint=null,
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	With Count_CTE 
	AS 
	(
		SELECT COUNT(*) AS TotalRow FROM TW_LoaiMucTieu lmt
		WHERE lmt.IDHTMT=@IDHTMT
		AND (@SuDung is null or (@SuDung is not null and lmt.SuDung=@SuDung))
	)
	SELECT lmt.*, Count_CTE.TotalRow
	FROM TW_LoaiMucTieu lmt
	CROSS JOIN Count_CTE
	WHERE lmt.IDHTMT=@IDHTMT
	AND (@SuDung is null or (@SuDung is not null and lmt.SuDung=@SuDung))
	ORDER BY lmt.ThuTu, lmt.TenLoaiMucTieu
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucDanhGia]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucDanhGia]
@IDChuThe tinyint,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	With Count_CTE 
	AS 
	(
		SELECT COUNT(*) AS TotalRow
		FROM TW_MucDanhGia
		WHERE IDKhachHang=@IDKhachHang
		AND ISNULL(IsDelete,0)=0
		AND (
				(@IDChuThe is null)
				OR
				(@IDChuThe is not null and IDChuThe=@IDChuThe)
			)
	)
	SELECT m.*,Count_CTE.TotalRow
	FROM TW_MucDanhGia m
	CROSS JOIN Count_CTE
	WHERE m.IDKhachHang=@IDKhachHang
	AND ISNULL(IsDelete,0)=0
	AND (
			(@IDChuThe is null)
			OR
			(@IDChuThe is not null and IDChuThe=@IDChuThe)
		)
	ORDER BY m.IDChuThe, m.DiemDen DESC, m.DiemTu DESC
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuCha]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuCha]
@IDHTMT	bigint = null,
@IDCha bigint=null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@IDTrangThaiDuyet tinyint=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDChucDanh bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@IDCapDuyet int,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN

	DECLARE @TMP_MucTieu TABLE( IDNhomMucTieu bigint NOT NULL,
								IDMucTieu bigint NOT NULL,
								IDKhachHang int NOT NULL,
								STT int NULL,
								TenMucTieu nvarchar(2000) NULL,
								MaMucTieu nvarchar(100) NULL,
								TrongSoPT decimal(13, 5) NULL,
								IDCoCau bigint NULL,
								IDNguoiPhuTrach bigint NULL,
								ThuTu smallint NULL,
								ThuTuCha smallint NULL,
								CapBacNhom tinyint NULL,
								PRIMARY KEY (IDNhomMucTieu, IDMucTieu)
							  );

	--@ChuThe: 0-Tổ chức, 1-Cá nhân
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (@IDCoCau IS NULL AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
	END;

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	--1: nhân sự, 2: Quản lý, 3: Bộ phận, 4: Chỉ định BP, 5: Toàn quyền
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4--Khong xem BP con
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);
	
	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND mt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
		AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
		AND (@IDTrangThaiDuyet Is null 
				OR (@IDTrangThaiDuyet=0 AND ISNULL(mt.IDTrangThaiDuyet,0) = 1)
				OR (@IDTrangThaiDuyet=1 AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10))
				OR (@IDTrangThaiDuyet=2 AND ISNULL(mt.IDTrangThaiDuyet,0) in (3,6,9))
				OR (@IDTrangThaiDuyet=3 AND ISNULL(mt.IDTrangThaiDuyet,0) in (2,5,8))
			)
		AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
		AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	DECLARE @CountKN int=0;
	SELECT @CountKN=COUNT(*) 
		FROM TW_TyTrongChucDanh ttcd
		LEFT JOIN SYS_NhanSu ns on ns.IDChucDanh=ttcd.IDChucDanh and ns.IDNhanSu=ttcd.IDNhanSu
		WHERE ttcd.IDHTMT=@IDHTMT 
			and ttcd.IDHTTS=@IDHTTS 
			and ttcd.IDNhanSu=@IDNguoiPhuTrach 
			and ISNULL(ttcd.TyTrong,0)>0
			AND ns.IDNhanSu is null;

	DECLARE @TotalRow int=1;

	SELECT @TotalRow=COUNT(*)
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0)
					AND (@CountKN=0 OR (@CountKN>0 AND ISNULL(mtts.IDChucDanh,0)=ISNULL(mt.IDChucDanh,0)))
				)
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@IDTrangThaiDuyet Is null 
			OR (@IDTrangThaiDuyet=0 AND ISNULL(mt.IDTrangThaiDuyet,0) = 1)
			OR (@IDTrangThaiDuyet=1 AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10))
			OR (@IDTrangThaiDuyet=2 AND ISNULL(mt.IDTrangThaiDuyet,0) in (3,6,9))
			OR (@IDTrangThaiDuyet=3 AND ISNULL(mt.IDTrangThaiDuyet,0) in (2,5,8))
		)
	AND (@IDCapDuyet is null 
		OR (@IDCapDuyet=1 and ISNULL(IDTrangThaiDuyet1,0) in (1,2))
		OR (@IDCapDuyet=2 and ISNULL(IDTrangThaiDuyet2,0) in (1,2))
		OR (@IDCapDuyet=3 and ISNULL(IDTrangThaiDuyet3,0) in (1,2))
	)
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'));

	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,TrongSoPT,IDKhachHang,IDCoCau,STT,ThuTu,ThuTuCha,CapBacNhom)
	SELECT mt.IDNhomMucTieu, mt.IDMucTieu,mt.MaMucTieu,mt.TenMucTieu,mtts.TrongSoPT,htmt.IDKhachHang,mt.IDCoCau,ROW_NUMBER() OVER (ORDER BY lmt.ThuTu,nmt.ThuTuCha, nmt.ThuTu,nmt.CapBac, mt.MaThuMuc) AS STT,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0)
					AND (@CountKN=0 OR (@CountKN>0 AND ISNULL(mtts.IDChucDanh,0)=ISNULL(mt.IDChucDanh,0)))
				)
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@IDTrangThaiDuyet Is null 
			OR (@IDTrangThaiDuyet=0 AND ISNULL(mt.IDTrangThaiDuyet,0) = 1)
			OR (@IDTrangThaiDuyet=1 AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10))
			OR (@IDTrangThaiDuyet=2 AND ISNULL(mt.IDTrangThaiDuyet,0) in (3,6,9))
			OR (@IDTrangThaiDuyet=3 AND ISNULL(mt.IDTrangThaiDuyet,0) in (2,5,8))
		)
	AND (@IDCapDuyet is null 
		OR (@IDCapDuyet=1 and ISNULL(IDTrangThaiDuyet1,0) in (1,2))
		OR (@IDCapDuyet=2 and ISNULL(IDTrangThaiDuyet2,0) in (1,2))
		OR (@IDCapDuyet=3 and ISNULL(IDTrangThaiDuyet3,0) in (1,2))
	)
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY STT
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
	
	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom,TrongSoPT)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,nmt.MaNhomMucTieu as MaMucTieu,nmt.TenNhomMucTieu as TenMucTieu,@IDKhachHang,0,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac,nmtts.TrongSoPT
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_DanhGia dg on dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS and dg.IDCoCau=ISNULL(@IDCoCau,0) and dg.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and dg.IDChucDanh=isnull(@IDChucDanh,0)
	LEFT JOIN TW_NhomMucTieuTrongSo nmtts on nmtts.IDDanhGia=dg.IDDanhGia and nmtts.IDNhomMucTieu=nmt.IDNhomMucTieu
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)>0 and ISNULL(nmt.SuDung,0)=1
	AND nmt.IDNhomMucTieu IN (SELECT distinct IDNhomMucTieu FROM @TMP_MucTieu)

	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom,TrongSoPT)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,nmt.MaNhomMucTieu as MaMucTieu,nmt.TenNhomMucTieu as TenMucTieu,@IDKhachHang,0,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac,nmtts.TrongSoPT
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_DanhGia dg on dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS and dg.IDCoCau=ISNULL(@IDCoCau,0) and dg.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and dg.IDChucDanh=isnull(@IDChucDanh,0)
	LEFT JOIN TW_NhomMucTieuTrongSo nmtts on nmtts.IDDanhGia=dg.IDDanhGia and nmtts.IDNhomMucTieu=nmt.IDNhomMucTieu
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)=0 and ISNULL(nmt.SuDung,0)=1
	AND (
			nmt.IDNhomMucTieu in  (SELECT IDNhomMucTieu from @TMP_MucTieu tmp WHERE tmp.IDMucTieu>0)
			OR
			nmt.IDNhomMucTieu in  (SELECT nmt.IDCha from @TMP_MucTieu tmp 
								INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu
								WHERE tmp.IDMucTieu<0)
		)
	
	--Kiểm tra nhóm mục tiêu
	DECLARE @CountNhom int=0;
	SELECT @CountNhom=COUNT(*) FROM @TMP_MucTieu WHERE IDMucTieu<0;
	IF(@CountNhom=0)
	BEGIN
		INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom)
		VALUES (0, 0-@TotalRow,'','',@IDKhachHang,0,0,0,0)
	END;
	
	SELECT tmp.*
	,ISNULL(mt.IDTrangThaiDuyet1,0) as IDTrangThaiDuyet1,ISNULL(mt.IDTrangThaiDuyet2,0) as IDTrangThaiDuyet2,ISNULL(mt.IDTrangThaiDuyet3,0) as IDTrangThaiDuyet3,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,mt.TrongSo,ccpt.TenCoCau as TenCoCauPT,ccpt.TenCoCauNgan as TenCoCauNganPT,
	ttmt.TenTrangThaiMucTieu, lts.TenLoaiTanSuat, npt.HoVaTen as TenNguoiPhuTrach, npt.TenNhanSuNgan, cd.TenChucDanh,cd.TenChucDanhNgan, cc.TenCoCau,cc.TenCoCauNgan, mt.KyHan,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	mt.NgayHoanThanh,round(ISNULL(mt.TyLeHoanThanh,mt.TyLeTamTinh),1) as TyLeHoanThanh,round(mt.DiemHoanThanh,2) as DiemHoanThanh,npt.AnhNhanSu,
	ISNULL(mt.CapBac,0) as CapBac,ISNULL(mt.CoLopCon,0) as CoLopCon, htts.TenTanSuat as KyDanhGia,
	mt.PhanHoi1,mt.PhanHoi2,mt.PhanHoi3,
	nsd1.MaNhanSu +' - '+ nsd1.HoVaTen as TenNguoiDuyet1,
	nsd2.MaNhanSu +' - '+ nsd2.HoVaTen as TenNguoiDuyet2,
	nsd3.MaNhanSu +' - '+ nsd3.HoVaTen as TenNguoiDuyet3,
	FORMAT(mt.NgayDuyet1, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet1,
	FORMAT(mt.NgayDuyet2, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet2,
	FORMAT(mt.NgayDuyet3, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet3
	FROM @TMP_MucTieu tmp
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieu mt on mt.IDMucTieu=tmp.IDMucTieu AND mt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=tmp.IDMucTieu
	LEFT JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=mt.IDHTMT and htts.IDHTTS=mt.IDHTTS and htts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=cc.IDNhomCap and nc.IDKhachHang=@IDKhachHang
	LEFT JOIN ENUM_TrangThaiMucTieu ttmt on ttmt.IDTrangThaiMucTieu=mt.IDTrangThaiMucTieu
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN SYS_NhanSu nsd1 on nsd1.IDNhanSu=mt.NguoiDuyet1
	LEFT JOIN SYS_NhanSu nsd2 on nsd2.IDNhanSu=mt.NguoiDuyet2
	LEFT JOIN SYS_NhanSu nsd3 on nsd3.IDNhanSu=mt.NguoiDuyet3
	ORDER BY lmt.ThuTu, tmp.ThuTuCha, tmp.ThuTu,tmp.IDNhomMucTieu,tmp.STT;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuCon]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuCon]
@IDHTMT	bigint = null,
@IDCha bigint=null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@IDTrangThaiDuyet tinyint=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDChucDanh bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@IDCapDuyet int,
@PageSize int = 1000, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN

	DECLARE @TMP_MucTieu TABLE( IDNhomMucTieu bigint NOT NULL,
								IDMucTieu bigint NOT NULL,
								IDKhachHang int NOT NULL,
								STT int NULL,
								TenMucTieu nvarchar(2000) NULL,
								MaMucTieu nvarchar(100) NULL,
								TrongSoPT decimal(13, 5) NULL,
								IDCoCau bigint NULL,
								IDNguoiPhuTrach bigint NULL,
								ThuTu smallint NULL,
								ThuTuCha smallint NULL,
								CapBacNhom tinyint NULL,
								PRIMARY KEY (IDNhomMucTieu, IDMucTieu)
							  );
	--@ChuThe: 0-Tổ chức, 1-Cá nhân
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (@IDCoCau IS NULL AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
	END;

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);
	
	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND mt.IDHTMT=@IDHTMT
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
		AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
		AND (@IDTrangThaiDuyet Is null 
				OR (@IDTrangThaiDuyet=0 AND ISNULL(mt.IDTrangThaiDuyet,0) = 1)
				OR (@IDTrangThaiDuyet=1 AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10))
				OR (@IDTrangThaiDuyet=2 AND ISNULL(mt.IDTrangThaiDuyet,0) in (3,6,9))
				OR (@IDTrangThaiDuyet=3 AND ISNULL(mt.IDTrangThaiDuyet,0) in (2,5,8))
			)
		AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
		AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	DECLARE @CountKN int=0;
	SELECT @CountKN=COUNT(*) 
		FROM TW_TyTrongChucDanh ttcd
		LEFT JOIN SYS_NhanSu ns on ns.IDChucDanh=ttcd.IDChucDanh and ns.IDNhanSu=ttcd.IDNhanSu
		WHERE ttcd.IDHTMT=@IDHTMT 
			and ttcd.IDHTTS=@IDHTTS 
			and ttcd.IDNhanSu=@IDNguoiPhuTrach 
			and ISNULL(ttcd.TyTrong,0)>0
			AND ns.IDNhanSu is null;

	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,IDCoCau,STT)
	SELECT mt.IDNhomMucTieu, mt.IDMucTieu,mt.MaMucTieu,mt.TenMucTieu,htmt.IDKhachHang,mt.IDCoCau,ROW_NUMBER() OVER (ORDER BY lmt.ThuTu,nmt.ThuTuCha, nmt.ThuTu,nmt.CapBac, mt.MaThuMuc) AS STT 
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0)
					AND (@CountKN=0 OR (@CountKN>0 AND ISNULL(mtts.IDChucDanh,0)=ISNULL(mt.IDChucDanh,0)))
				)
			)
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND ISNULL(mt.IDMucTieuCha,0) = ISNULL(@IDCha,0)
	AND mt.IDHTMT=@IDHTMT
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@IDTrangThaiDuyet Is null 
			OR (@IDTrangThaiDuyet=0 AND ISNULL(mt.IDTrangThaiDuyet,0) = 1)
			OR (@IDTrangThaiDuyet=1 AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10))
			OR (@IDTrangThaiDuyet=2 AND ISNULL(mt.IDTrangThaiDuyet,0) in (3,6,9))
			OR (@IDTrangThaiDuyet=3 AND ISNULL(mt.IDTrangThaiDuyet,0) in (2,5,8))
		)
	AND (@IDCapDuyet is null 
		OR (@IDCapDuyet=1 and ISNULL(IDTrangThaiDuyet1,0) in (1,2))
		OR (@IDCapDuyet=2 and ISNULL(IDTrangThaiDuyet2,0) in (1,2))
		OR (@IDCapDuyet=3 and ISNULL(IDTrangThaiDuyet3,0) in (1,2))
	)
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	--AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY STT
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
	
	SELECT tmp.*, ISNULL(mt.IDTrangThaiDuyet1,0) as IDTrangThaiDuyet1,ISNULL(mt.IDTrangThaiDuyet2,0) as IDTrangThaiDuyet2,ISNULL(mt.IDTrangThaiDuyet3,0) as IDTrangThaiDuyet3,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,mt.TrongSo,ccpt.TenCoCau as TenCoCauPT,ccpt.TenCoCauNgan as TenCoCauNganPT,
	ttmt.TenTrangThaiMucTieu, lts.TenLoaiTanSuat, npt.HoVaTen as TenNguoiPhuTrach, npt.TenNhanSuNgan, cd.TenChucDanh,cd.TenChucDanhNgan, cc.TenCoCau,cc.TenCoCauNgan, mt.KyHan,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	mt.NgayHoanThanh,round(ISNULL(mt.TyLeHoanThanh,mt.TyLeTamTinh),1) as TyLeHoanThanh,round(mt.DiemHoanThanh,2) as DiemHoanThanh,npt.AnhNhanSu,
	ISNULL(mt.CapBac,0) as CapBac,ISNULL(mt.CoLopCon,0) as CoLopCon, htts.TenTanSuat as KyDanhGia,
	mt.PhanHoi1,mt.PhanHoi2,mt.PhanHoi3,
	nsd1.MaNhanSu +' - '+ nsd1.HoVaTen as TenNguoiDuyet1,
	nsd2.MaNhanSu +' - '+ nsd2.HoVaTen as TenNguoiDuyet2,
	nsd3.MaNhanSu +' - '+ nsd3.HoVaTen as TenNguoiDuyet3,
	FORMAT(mt.NgayDuyet1, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet1,
	FORMAT(mt.NgayDuyet2, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet2,
	FORMAT(mt.NgayDuyet3, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet3
	FROM @TMP_MucTieu tmp
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieu mt on mt.IDMucTieu=tmp.IDMucTieu AND mt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=tmp.IDMucTieu
	LEFT JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=mt.IDHTMT and htts.IDHTTS=mt.IDHTTS and htts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=cc.IDNhomCap and nc.IDKhachHang=@IDKhachHang
	LEFT JOIN ENUM_TrangThaiMucTieu ttmt on ttmt.IDTrangThaiMucTieu=mt.IDTrangThaiMucTieu
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN SYS_NhanSu nsd1 on nsd1.IDNhanSu=mt.NguoiDuyet1
	LEFT JOIN SYS_NhanSu nsd2 on nsd2.IDNhanSu=mt.NguoiDuyet2
	LEFT JOIN SYS_NhanSu nsd3 on nsd3.IDNhanSu=mt.NguoiDuyet3
	ORDER BY lmt.ThuTu, tmp.ThuTuCha, tmp.ThuTu,tmp.IDNhomMucTieu,tmp.STT;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuCongViec]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuCongViec]
@IDHTMT	bigint,
@IDHTTS bigint,
@IDNhomCap tinyint =null,
@IDCoCau bigint=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	SELECT mt.*,dvt.TenDonViTinh,dvt.IDKieuDuLieu,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	round(ISNULL(mt.TyLeHoanThanh,mt.TyLeTamTinh),2) as TyLeHoanThanh,
	(CASE 
		WHEN mt.CTSoThucTe is null then CAST(1 as tinyint)
		ELSE CAST(0 as tinyint)
	END) as bSua
	FROM TW_MucTieu mt
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE mt.IDHTMT=@IDHTMT
	AND (@IDHTTS IS NULL OR mt.IDHTTS=@IDHTTS)
	AND mt.IDNguoiPhuTrach=@IDNguoiPhuTrach
	AND ISNULL(mt.IsDelete,0)=@IsDelete
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY mt.IDMucTieu
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuCongViecLich]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuCongViecLich]
@IDHTMT	bigint,
@IDHTTS bigint,
@IDNhomCap tinyint =null,
@IDCoCau bigint=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@DateFrom date,
@DateTo date,
@IsDelete bit=0,
@SuDung bit=null,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	SELECT mt.*,dvt.TenDonViTinh,dvt.IDKieuDuLieu,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	round(ISNULL(mt.TyLeHoanThanh,mt.TyLeTamTinh),2) as TyLeHoanThanh
	FROM TW_MucTieu mt
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	INNER JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	WHERE mt.IDHTMT=@IDHTMT
	AND (@IDHTTS IS NULL OR mt.IDHTTS=@IDHTTS)
	AND mt.IDNguoiPhuTrach=@IDNguoiPhuTrach
	AND ISNULL(mt.IsDelete,0)=@IsDelete
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	AND (mt.KyHan BETWEEN @DateFrom AND @DateTo)
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY mt.KyHan, mt.MaThuMuc
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuDanhGia]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuDanhGia]
@IDHTMT	bigint = null,
@IDCha bigint=null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IsDanhGia tinyint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@IDTrangThaiDuyet tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDChucDanh bigint=null,
@IDLoaiMucTieu tinyint=null,
@IDCapDuyet int,
@IDTrangThaiCapDuyet int,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IDQuyenDuyet1 int,
@IDQuyenDuyet2 int,
@IDQuyenDuyet3 int
AS
BEGIN
	
	--@ChuThe: 0-Tổ chức, 1-Cá nhân
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (@IDCoCau IS NULL AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
	END;

	DECLARE @TMP_MucTieuDanhGia TABLE( IDNhomMucTieu bigint NOT NULL,
										IDMucTieu bigint NOT NULL,
										IDKhachHang int NOT NULL,
										STT int NULL,
										TenMucTieu nvarchar(2000) NULL,
										MaMucTieu nvarchar(100) NULL,
										TyLeHoanThanh decimal(9, 2) NULL,
										DiemHoanThanh decimal(13, 5) NULL,
										ThuTu smallint NULL,
										ThuTuCha smallint NULL,
										CapBacNhom tinyint NULL,
										bNhap bit NULL,
										bDuyet1 bit NULL,
										bDuyet2 bit NULL,
										bDuyet3 bit NULL,
										TrongSoPT decimal(13, 5) NULL,
										PRIMARY KEY (IDNhomMucTieu, IDMucTieu)
									 );
	
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;
	
	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	DECLARE @TableCD TABLE(id bigint NOT NULL);
	
	INSERT INTO @TableCD (id) VALUES (@Q_IDChucDanh);
	INSERT INTO @TableCD (id) 
	SELECT cd.IDChucDanh 
	FROM SYS_NhanSu ns
	INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
	INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
	WHERE ns.IDNhanSu=@IDNhanSu;
	
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);
	
	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
		INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
		where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		AND mt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Đã duyệt 1/2/3
		AND ISNULL(mt.IsDelete,0) = 0
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (
				@ChuThe is null
				OR (ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
				OR (ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
			)
		AND (@IDTrangThaiDuyet is null
			OR (@idCapDuyet=0)
			OR (@idCapDuyet=1 AND ISNULL(@IDTrangThaiDuyet,0)=ISNULL(nkq.IDTrangThaiDuyet1,0))
			OR (@idCapDuyet=2 AND ISNULL(@IDTrangThaiDuyet,0)=ISNULL(nkq.IDTrangThaiDuyet2,0))
			OR (@idCapDuyet=3 AND ISNULL(@IDTrangThaiDuyet,0)=ISNULL(nkq.IDTrangThaiDuyet3,0))
			)
		AND (@IDTrangThaiCapDuyet is null or nkq.IDTrangThaiDuyet=@IDTrangThaiCapDuyet)
		AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	DECLARE @CountKN int=0;
	SELECT @CountKN=COUNT(*) 
		FROM TW_TyTrongChucDanh ttcd
		LEFT JOIN SYS_NhanSu ns on ns.IDChucDanh=ttcd.IDChucDanh and ns.IDNhanSu=ttcd.IDNhanSu
		WHERE ttcd.IDHTMT=@IDHTMT 
			and ttcd.IDHTTS=@IDHTTS 
			and ttcd.IDNhanSu=@IDNguoiPhuTrach 
			and ISNULL(ttcd.TyTrong,0)>0
			AND ns.IDNhanSu is null;

	DECLARE @TotalRow int=0;
	SELECT @TotalRow=COUNT(*)
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND mtts.IDCoCau=0 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0)
					AND (@CountKN=0 OR (@CountKN>0 AND ISNULL(mtts.IDChucDanh,0)=ISNULL(mt.IDChucDanh,0)))
				)
			)
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	--Quyền Nhập
	--LEFT JOIN TW_DoiTuongNhap dtnCD on dtnCD.IDDoiTuong=@Q_IDChucDanh and dtnCD.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=2--Chức danh chỉ định NHẬP
	LEFT JOIN (SELECT IDDoiTuong,IDMucTieu,row_number() over (partition by IDMucTieu order by IDDoiTuong desc) as STT FROM TW_DoiTuongNhap INNER JOIN @TableCD tmp ON tmp.id=TW_DoiTuongNhap.IDDoiTuong) dtnCD 
		on dtnCD.STT=1 and dtnCD.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=2--Chức danh chỉ định NHẬP
	LEFT JOIN TW_DoiTuongNhap dtnNS on dtnNS.IDDoiTuong=@IDNhanSu and dtnNS.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=3--Nhân sự chỉ định NHẬP
	--Quyền Duyệt 1
	--LEFT JOIN TW_DoiTuongDuyet dtdCD1 on dtdCD1.IDDoiTuong=@Q_IDChucDanh and dtdCD1.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=2--Chức danh chỉ định DUYỆT 1
	LEFT JOIN (SELECT IDDoiTuong,IDMucTieu,row_number() over (partition by IDMucTieu order by IDDoiTuong desc) as STT FROM TW_DoiTuongDuyet INNER JOIN @TableCD tmp ON tmp.id=TW_DoiTuongDuyet.IDDoiTuong) dtdCD1 
		on dtdCD1.STT=1 and dtdCD1.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=2--Chức danh chỉ định DUYỆT 1
	LEFT JOIN TW_DoiTuongDuyet dtdNS1 on dtdNS1.IDDoiTuong=@IDNhanSu and dtdNS1.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=3--Nhân sự chỉ định DUYỆT 1
	--Quyền Duyệt 2
	--LEFT JOIN TW_DoiTuongDuyet2 dtdCD2 on dtdCD2.IDDoiTuong=@Q_IDChucDanh and dtdCD2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=2--Chức danh chỉ định DUYỆT 2
	LEFT JOIN (SELECT IDDoiTuong,IDMucTieu,row_number() over (partition by IDMucTieu order by IDDoiTuong desc) as STT FROM TW_DoiTuongDuyet2 INNER JOIN @TableCD tmp ON tmp.id=TW_DoiTuongDuyet2.IDDoiTuong) dtdCD2 
		on dtdCD2.STT=1 and dtdCD2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=2--Chức danh chỉ định DUYỆT 2
	LEFT JOIN TW_DoiTuongDuyet2 dtdNS2 on dtdNS2.IDDoiTuong=@IDNhanSu and dtdNS2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=3--Nhân sự chỉ định DUYỆT 2
	--Quyền Duyệt 3
	--LEFT JOIN TW_DoiTuongDuyet3 dtdCD3 on dtdCD3.IDDoiTuong=@Q_IDChucDanh and dtdCD3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=2--Chức danh chỉ định DUYỆT 3
	LEFT JOIN (SELECT IDDoiTuong,IDMucTieu,row_number() over (partition by IDMucTieu order by IDDoiTuong desc) as STT FROM TW_DoiTuongDuyet3 INNER JOIN @TableCD tmp ON tmp.id=TW_DoiTuongDuyet3.IDDoiTuong) dtdCD3 
		on dtdCD3.STT=1 and dtdCD3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=2--Chức danh chỉ định DUYỆT 3
	LEFT JOIN TW_DoiTuongDuyet3 dtdNS3 on dtdNS3.IDDoiTuong=@IDNhanSu and dtdNS3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=3--Nhân sự chỉ định DUYỆT 3
	
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
						OR (dtnCD.IDDoiTuong is not null)
						OR (dtnNS.IDDoiTuong is not null)
						OR (dtdCD1.IDDoiTuong is not null)
						OR (dtdNS1.IDDoiTuong is not null)
						OR (dtdCD2.IDDoiTuong is not null)
						OR (dtdNS2.IDDoiTuong is not null)
						OR (dtdCD3.IDDoiTuong is not null)
						OR (dtdNS3.IDDoiTuong is not null)
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Đã duyệt 1/2/3
	AND ISNULL(mt.IsDelete,0) = 0
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDChucDanh Is null OR (@IDChucDanh is not null and mt.IDChucDanh=@IDChucDanh))
	AND (
			@ChuThe is null
			OR (ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR (ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDTrangThaiDuyet is null
		OR (@idCapDuyet=0)
		OR (@idCapDuyet=1 AND ISNULL(@IDTrangThaiDuyet,0)=ISNULL(nkq.IDTrangThaiDuyet1,0))
		OR (@idCapDuyet=2 AND ISNULL(@IDTrangThaiDuyet,0)=ISNULL(nkq.IDTrangThaiDuyet2,0))
		OR (@idCapDuyet=3 AND ISNULL(@IDTrangThaiDuyet,0)=ISNULL(nkq.IDTrangThaiDuyet3,0))
		)
	AND (@IDTrangThaiCapDuyet is null or nkq.IDTrangThaiDuyet=@IDTrangThaiCapDuyet)
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'));
	
	INSERT INTO @TMP_MucTieuDanhGia (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom,bNhap,bDuyet1,bDuyet2,bDuyet3)
	SELECT mt.IDNhomMucTieu, mt.IDMucTieu,@IDKhachHang, ROW_NUMBER() OVER (ORDER BY lmt.ThuTu,nmt.ThuTuCha, nmt.ThuTu,nmt.CapBac, mt.MaThuMuc) AS STT,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac,
			(CASE 
			    WHEN mt.CTSoThucTe is null and @IDQuyen=5 then 1
				WHEN mt.CTSoThucTe is null and (@IDQuyen=2 OR @IDQuyen=3) AND (mt.IDCoCau in (select id from @TableID) OR mt.IDChucDanh in (select id from @TableCD) OR npt.IDCoCau in (select id from @TableID)) then 1
			    WHEN mt.CTSoThucTe is null and (@IDQuyen=4 AND (mt.IDCoCau in (select id from @TableID) OR mt.IDChucDanh in (select id from @TableCD) OR npt.IDCoCau in (select id from @TableID))) then 1
				WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenNhap,0)=0 then 1--Tất cả nhân sự
				WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenNhap,0)=1 then 1 --Theo cấp chỉ tiêu
				WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenNhap,0)=2 and dtnCD.IDMucTieu is not null then 1
				WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenNhap,0)=3 and dtnNS.IDMucTieu is not null then 1
				ELSE 0
			END) as bNhap,
			(CASE 
			    WHEN mt.CTSoThucTe is null and @IDQuyenDuyet1=5 then 1
				WHEN mt.CTSoThucTe is null and (@IDQuyenDuyet1=2 OR @IDQuyenDuyet1=3) AND (mt.IDCoCau in (select id from @TableID) OR mt.IDChucDanh in (select id from @TableCD) OR npt.IDCoCau in (select id from @TableID)) then 1
			    WHEN mt.CTSoThucTe is null and (@IDQuyenDuyet1=4 AND (mt.IDCoCau in (select id from @TableID) OR mt.IDChucDanh in (select id from @TableCD) OR npt.IDCoCau in (select id from @TableID))) then 1
				WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenDuyet,0)=1 then 1 --Theo cấp chỉ tiêu
				WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenDuyet,0)=2 and dtdCD1.IDMucTieu is not null then 1
				WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenDuyet,0)=3 and dtdNS1.IDMucTieu is not null then 1
				ELSE 0
			END) as bDuyet1,
			(CASE 
			    WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenDuyet2,0)>0 and @IDQuyenDuyet2=5 then 1
				WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenDuyet2,0)>0 and (@IDQuyenDuyet2=2 OR @IDQuyenDuyet2=3) AND (mt.IDCoCau in (select id from @TableID) OR mt.IDChucDanh in (select id from @TableCD) OR npt.IDCoCau in (select id from @TableID)) then 1
			    WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenDuyet2,0)>0 and (@IDQuyenDuyet2=4 AND (mt.IDCoCau in (select id from @TableID) OR mt.IDChucDanh in (select id from @TableCD) OR npt.IDCoCau in (select id from @TableID))) then 1
				WHEN mt.CTSoThucTe is null and dtdCD2.IDMucTieu is not null or dtdNS2.IDMucTieu is not null then 1
				ELSE 0
			END) as bDuyet2,
			(CASE 
			    WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenDuyet3,0)>0 and @IDQuyenDuyet3=5 then 1
				WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenDuyet3,0)>0 and (@IDQuyenDuyet3=2 OR @IDQuyenDuyet3=3) AND (mt.IDCoCau in (select id from @TableID) OR mt.IDChucDanh in (select id from @TableCD) OR npt.IDCoCau in (select id from @TableID)) then 1
			    WHEN mt.CTSoThucTe is null and ISNULL(mt.IDQuyenDuyet3,0)>0 and (@IDQuyenDuyet3=4 AND (mt.IDCoCau in (select id from @TableID) OR mt.IDChucDanh in (select id from @TableCD) OR npt.IDCoCau in (select id from @TableID))) then 1
				WHEN mt.CTSoThucTe is null and dtdCD3.IDMucTieu is not null or dtdNS3.IDMucTieu is not null then 1
				ELSE 0
			END) as bDuyet3
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND mtts.IDCoCau=0 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0)
					AND (@CountKN=0 OR (@CountKN>0 AND ISNULL(mtts.IDChucDanh,0)=ISNULL(mt.IDChucDanh,0)))
				)
			)
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	--Quyền Nhập
	--LEFT JOIN TW_DoiTuongNhap dtnCD on dtnCD.IDDoiTuong=@Q_IDChucDanh and dtnCD.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=2--Chức danh chỉ định NHẬP
	LEFT JOIN (SELECT IDDoiTuong,IDMucTieu,row_number() over (partition by IDMucTieu order by IDDoiTuong desc) as STT FROM TW_DoiTuongNhap INNER JOIN @TableCD tmp ON tmp.id=TW_DoiTuongNhap.IDDoiTuong) dtnCD 
		on dtnCD.STT=1 and dtnCD.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=2--Chức danh chỉ định NHẬP
	LEFT JOIN TW_DoiTuongNhap dtnNS on dtnNS.IDDoiTuong=@IDNhanSu and dtnNS.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=3--Nhân sự chỉ định NHẬP
	--Quyền Duyệt 1
	--LEFT JOIN TW_DoiTuongDuyet dtdCD1 on dtdCD1.IDDoiTuong=@Q_IDChucDanh and dtdCD1.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=2--Chức danh chỉ định DUYỆT 1
	LEFT JOIN (SELECT IDDoiTuong,IDMucTieu,row_number() over (partition by IDMucTieu order by IDDoiTuong desc) as STT FROM TW_DoiTuongDuyet INNER JOIN @TableCD tmp ON tmp.id=TW_DoiTuongDuyet.IDDoiTuong) dtdCD1 
		on dtdCD1.STT=1 and dtdCD1.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=2--Chức danh chỉ định DUYỆT 1
	LEFT JOIN TW_DoiTuongDuyet dtdNS1 on dtdNS1.IDDoiTuong=@IDNhanSu and dtdNS1.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=3--Nhân sự chỉ định DUYỆT 1
	--Quyền Duyệt 2
	--LEFT JOIN TW_DoiTuongDuyet2 dtdCD2 on dtdCD2.IDDoiTuong=@Q_IDChucDanh and dtdCD2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=2--Chức danh chỉ định DUYỆT 2
	LEFT JOIN (SELECT IDDoiTuong,IDMucTieu,row_number() over (partition by IDMucTieu order by IDDoiTuong desc) as STT FROM TW_DoiTuongDuyet2 INNER JOIN @TableCD tmp ON tmp.id=TW_DoiTuongDuyet2.IDDoiTuong) dtdCD2 
		on dtdCD2.STT=1 and dtdCD2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=2--Chức danh chỉ định DUYỆT 2
	LEFT JOIN TW_DoiTuongDuyet2 dtdNS2 on dtdNS2.IDDoiTuong=@IDNhanSu and dtdNS2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=3--Nhân sự chỉ định DUYỆT 2
	--Quyền Duyệt 3
	--LEFT JOIN TW_DoiTuongDuyet3 dtdCD3 on dtdCD3.IDDoiTuong=@Q_IDChucDanh and dtdCD3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=2--Chức danh chỉ định DUYỆT 3
	LEFT JOIN (SELECT IDDoiTuong,IDMucTieu,row_number() over (partition by IDMucTieu order by IDDoiTuong desc) as STT FROM TW_DoiTuongDuyet3 INNER JOIN @TableCD tmp ON tmp.id=TW_DoiTuongDuyet3.IDDoiTuong) dtdCD3 
		on dtdCD3.STT=1 and dtdCD3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=2--Chức danh chỉ định DUYỆT 3
	LEFT JOIN TW_DoiTuongDuyet3 dtdNS3 on dtdNS3.IDDoiTuong=@IDNhanSu and dtdNS3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=3--Nhân sự chỉ định DUYỆT 3
	
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
						OR (dtnCD.IDDoiTuong is not null)
						OR (dtnNS.IDDoiTuong is not null)
						OR (dtdCD1.IDDoiTuong is not null)
						OR (dtdNS1.IDDoiTuong is not null)
						OR (dtdCD2.IDDoiTuong is not null)
						OR (dtdNS2.IDDoiTuong is not null)
						OR (dtdCD3.IDDoiTuong is not null)
						OR (dtdNS3.IDDoiTuong is not null)
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Đã duyệt 1/2/3
	AND ISNULL(mt.IsDelete,0) = 0
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDChucDanh Is null OR (@IDChucDanh is not null and mt.IDChucDanh=@IDChucDanh))
	AND (
			@ChuThe is null
			OR (ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR (ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	--AND (
	--		(ISNULL(@IsDanhGia,0)=0)
	--		OR 
	--		(ISNULL(@IsDanhGia,0)=1 AND ISNULL(nkq.IDTrangThaiDuyet,0) in (4,7,10))--Duyệt cấp 1,2,3
	--	)
	AND (@IDTrangThaiDuyet is null
		OR (@idCapDuyet=0)
		OR (@idCapDuyet=1 AND ISNULL(@IDTrangThaiDuyet,0)=ISNULL(nkq.IDTrangThaiDuyet1,0))
		OR (@idCapDuyet=2 AND ISNULL(@IDTrangThaiDuyet,0)=ISNULL(nkq.IDTrangThaiDuyet2,0))
		OR (@idCapDuyet=3 AND ISNULL(@IDTrangThaiDuyet,0)=ISNULL(nkq.IDTrangThaiDuyet3,0))
		)
	AND (@IDTrangThaiCapDuyet is null or nkq.IDTrangThaiDuyet=@IDTrangThaiCapDuyet)
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ISNULL(mt.IDNguoiPhuTrach,0) = ISNULL(@IDNguoiPhuTrach,0)))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY STT
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
	
	INSERT INTO @TMP_MucTieuDanhGia (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,TenMucTieu,MaMucTieu,TyLeHoanThanh,DiemHoanThanh,ThuTu,ThuTuCha,CapBacNhom,TrongSoPT)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,@IDKhachHang,0 as STT,nmt.TenNhomMucTieu as TenMucTieu,nmt.MaNhomMucTieu,
	--nmtkq.TyLeHoanThanh,
	--nmtkq.DiemHoanThanh,
	(CASE WHEN @IsDanhGia=1 and @IDChucDanh>0 THEN nmtkq.TyLeHoanThanh 
		  WHEN @IsDanhGia=0 and @IDChucDanh>0 THEN nmtkq.TyLeTamTinh 
		  ELSE null END
	) as TyLeHoanThanh,
	(CASE WHEN @IsDanhGia=1 and @IDChucDanh>0 THEN nmtkq.DiemHoanThanh 
		  WHEN @IsDanhGia=0 and @IDChucDanh>0 THEN nmtkq.DiemTamTinh 
		  ELSE null END
	) as DiemHoanThanh,
	nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac,
	nmtts.TrongSoPTDuyet
	--(CASE WHEN @IsDanhGia=1 THEN nmtts.TrongSoPTDuyet ELSE nmtts.TrongSoPT END)
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_DanhGia dg on dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS and dg.IDCoCau=ISNULL(@IDCoCau,0) and dg.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) AND DG.IDChucDanh=isnull(@IDChucDanh,0)
	LEFT JOIN TW_NhomMucTieuTrongSo nmtts on nmtts.IDDanhGia=dg.IDDanhGia and nmtts.IDNhomMucTieu=nmt.IDNhomMucTieu
	LEFT JOIN TW_NhomMucTieuKetQua nmtkq on nmtkq.IDHTMT=@IDHTMT and nmtkq.IDNhomMucTieu=nmt.IDNhomMucTieu and nmtkq.IDHTTS=@IDHTTS
											and nmtkq.IDCoCau=ISNULL(@IDCoCau,0) and nmtkq.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and nmtkq.IDChucDanh=ISNULL(@IDChucDanh,0)
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)>0 and ISNULL(nmt.SuDung,0)=1
	AND nmt.IDNhomMucTieu IN (SELECT distinct IDNhomMucTieu FROM @TMP_MucTieuDanhGia)

	INSERT INTO @TMP_MucTieuDanhGia (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,TenMucTieu,MaMucTieu,TyLeHoanThanh,DiemHoanThanh,ThuTu,ThuTuCha,CapBacNhom,TrongSoPT)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,@IDKhachHang,0 as STT,nmt.TenNhomMucTieu as TenMucTieu,nmt.MaNhomMucTieu,
	--nmtkq.TyLeHoanThanh,
	--nmtkq.DiemHoanThanh,
	(CASE WHEN @IsDanhGia=1 and @IDChucDanh>0 THEN nmtkq.TyLeHoanThanh 
		  WHEN @IsDanhGia=0 and @IDChucDanh>0 THEN nmtkq.TyLeTamTinh 
		  ELSE null END
	) as TyLeHoanThanh,
	(CASE WHEN @IsDanhGia=1 and @IDChucDanh>0 THEN nmtkq.DiemHoanThanh 
		  WHEN @IsDanhGia=0 and @IDChucDanh>0 THEN nmtkq.DiemTamTinh 
		  ELSE null END
	) as DiemHoanThanh,
	nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac,
	nmtts.TrongSoPTDuyet
	--(CASE WHEN @IsDanhGia=1 THEN nmtts.TrongSoPTDuyet ELSE nmtts.TrongSoPT END)
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_DanhGia dg on dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS and dg.IDCoCau=ISNULL(@IDCoCau,0) and dg.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) AND DG.IDChucDanh=isnull(@IDChucDanh,0)
	LEFT JOIN TW_NhomMucTieuTrongSo nmtts on nmtts.IDDanhGia=dg.IDDanhGia and nmtts.IDNhomMucTieu=nmt.IDNhomMucTieu
	LEFT JOIN TW_NhomMucTieuKetQua nmtkq on nmtkq.IDHTMT=@IDHTMT and nmtkq.IDNhomMucTieu=nmt.IDNhomMucTieu and nmtkq.IDHTTS=@IDHTTS
											and nmtkq.IDCoCau=ISNULL(@IDCoCau,0) and nmtkq.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and nmtkq.IDChucDanh=ISNULL(@IDChucDanh,0)
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)=0 and ISNULL(nmt.SuDung,0)=1
	AND (
			nmt.IDNhomMucTieu in  (SELECT IDNhomMucTieu from @TMP_MucTieuDanhGia tmp WHERE tmp.IDMucTieu>0)
			OR
			nmt.IDNhomMucTieu in  (SELECT nmt.IDCha from @TMP_MucTieuDanhGia tmp 
								INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu
								WHERE tmp.IDMucTieu<0)
		)
	
	--Kiểm tra nhóm mục tiêu
	DECLARE @CountNhom int=0;
	SELECT @CountNhom=COUNT(*) FROM @TMP_MucTieuDanhGia WHERE IDMucTieu<0;
	IF(@CountNhom=0)
	BEGIN
		INSERT INTO @TMP_MucTieuDanhGia (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,TenMucTieu,MaMucTieu,TyLeHoanThanh,DiemHoanThanh,ThuTu,ThuTuCha,CapBacNhom)
		VALUES (0, 0-@TotalRow,@IDKhachHang,0,'','',null,null,0,0,0)
	END;
	
	SELECT tmp.IDNhomMucTieu,
			tmp.IDMucTieu,
			ISNULL(tmp.TenMucTieu,mt.TenMucTieu) as TenMucTieu,
			ISNULL(tmp.MaMucTieu,mt.MaMucTieu) as MaMucTieu,
			mt.SoKeHoachSo,
			FORMAT(mt.SoKeHoachNgay, 'yyyy-MM-dd') as sSoKeHoachNgay,
			mt.SoKeHoachTyLe,
			--ISNULL(tmp.TyLeHoanThanh,mt.TyLeHoanThanh) as TyLeHoanThanh,
			--ISNULL(tmp.DiemHoanThanh,mt.DiemHoanThanh) as DiemHoanThanh,
			(CASE WHEN @IsDanhGia=1 THEN ISNULL(tmp.TyLeHoanThanh,mt.TyLeHoanThanh)
				  WHEN @IsDanhGia=0 THEN ISNULL(tmp.TyLeHoanThanh,mt.TyLeTamTinh)
				  ELSE null END
			) as TyLeHoanThanh,
			(CASE WHEN @IsDanhGia=1 THEN ISNULL(tmp.DiemHoanThanh,mt.DiemHoanThanh)
				  WHEN @IsDanhGia=0 THEN ISNULL(tmp.DiemHoanThanh,mt.DiemTamTinh)
				  ELSE null END
			) as DiemHoanThanh,
			(CASE WHEN @IDCapDuyet=0 THEN ISNULL(tmp.TrongSoPT,mtts.TrongSoPTTamTinh)
			ELSE ISNULL(tmp.TrongSoPT,mtts.TrongSoPT) END
			) as TrongSoPT,
			(CASE 
			    WHEN dvt.IDKieuDuLieu=1 and lower(mt.CTSoThucTe) = lower('DoanhSo') then DSo.totalSales
			    WHEN dvt.IDKieuDuLieu=1 and lower(mt.CTSoThucTe) = lower('DoanhThu') then DThu.totalRevenue
			    WHEN dvt.IDKieuDuLieu=1 and lower(mt.CTSoThucTe) = lower('KhachHangMoi') then KHang.totalCustomer
			    WHEN dvt.IDKieuDuLieu=1 and lower(mt.CTSoThucTe) = lower('KhachHangTuongTac') then KHangTT.totalCustomer
				ELSE nkq.SoThucTeSo
			END) as SoThucTeSo,
			(CASE 
			    WHEN dvt.IDKieuDuLieu=3 and lower(mt.CTSoThucTe) = lower('DoanhSo') then DSo.totalSales
			    WHEN dvt.IDKieuDuLieu=3 and lower(mt.CTSoThucTe) = lower('DoanhThu') then DThu.totalRevenue
			    WHEN dvt.IDKieuDuLieu=3 and lower(mt.CTSoThucTe) = lower('KhachHangMoi') then KHang.totalCustomer
			    WHEN dvt.IDKieuDuLieu=3 and lower(mt.CTSoThucTe) = lower('KhachHangTuongTac') then KHangTT.totalCustomer
				ELSE nkq.SoThucTeTyLe
			END) as SoThucTeTyLe,
			FORMAT(nkq.SoThucTeNgay, 'yyyy-MM-dd') as sSoThucTeNgay,
			nkq.SoThucTeSo1,
			FORMAT(nkq.SoThucTeNgay1, 'yyyy-MM-dd') as sSoThucTeNgay1,
			nkq.SoThucTeTyLe1,
			nkq.SoThucTeSo2,
			FORMAT(nkq.SoThucTeNgay2, 'yyyy-MM-dd') as sSoThucTeNgay2,
			nkq.SoThucTeTyLe2,
			nkq.SoThucTeSo3,
			FORMAT(nkq.SoThucTeNgay3, 'yyyy-MM-dd') as sSoThucTeNgay3,
			nkq.SoThucTeTyLe3,
			nsd0.MaNhanSu +' - '+ nsd0.HoVaTen as TenNguoiThuyetMinh,
			nsd1.MaNhanSu +' - '+ nsd1.HoVaTen as TenNguoiDuyet1,
			nsd2.MaNhanSu +' - '+ nsd2.HoVaTen as TenNguoiDuyet2,
			nsd3.MaNhanSu +' - '+ nsd3.HoVaTen as TenNguoiDuyet3,
			FORMAT(nkq.NgayThuyetMinh, 'yyyy-MM-dd hh:mm:ss') as sNgayThuyetMinh,
			FORMAT(nkq.NgayDuyet1, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet1,
			FORMAT(nkq.NgayDuyet2, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet2,
			FORMAT(nkq.NgayDuyet3, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet3,
			mt.TrongSo,
			mt.KyHan,
			tmp.CapBacNhom,
			ISNULL(nkq.IDTrangThaiDuyet,0) as IDTrangThaiDuyet,
			ISNULL(nkq.IDTrangThaiDuyet1,0) as IDTrangThaiDuyet1,
			ISNULL(nkq.IDTrangThaiDuyet2,0) as IDTrangThaiDuyet2,
			ISNULL(nkq.IDTrangThaiDuyet3,0) as IDTrangThaiDuyet3,
			nkq.PhanHoi1,nkq.PhanHoi2,nkq.PhanHoi3,nkq.ThuyetMinh,
			bNhap,bDuyet1,bDuyet2,bDuyet3,
			(CASE 
			    WHEN mt.CTSoThucTe is null then null
				ELSE '1'
			END) as CTSoThucTe,
	dvt.IDKieuDuLieu,dvt.TenDonViTinh,lts.TenLoaiTanSuat,
	cc.IDCoCau, cc.TenCoCau, npt.HoVaTen as TenNguoiPhuTrach, cd.TenChucDanh, ccpt.TenCoCau as TenCoCauPT, npt.AnhNhanSu,
	htts.TenTanSuat as KyDanhGia,
	ISNULL(mt.FileDinhKem,0) as FileDinhKem
	FROM @TMP_MucTieuDanhGia tmp
	LEFT JOIN TW_MucTieu mt on mt.IDMucTieu=tmp.IDMucTieu and tmp.IDMucTieu>0
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=@IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=mt.IDHTMT and htts.IDHTTS=mt.IDHTTS and htts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	--LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=tmp.IDNhomCap and nc.IDKhachHang=@IDKhachHang
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	LEFT JOIN CRM_CTL_Sale DSo on DSo.IDHTTS=mt.IDHTTS and lower(mt.CTSoThucTe) = lower('DoanhSo') and 
		(
		 (mt.IDCoCau=0 and Dso.groupBy=3 and lower(npt.DB_UserName)=lower(DSo.salesmanEmail))
		 OR
		 (mt.IDCoCau>0 and Dso.groupBy in (1,2) and lower(ISNULL(cc.MaTichHop,cc.MaCoCau))=lower(DSo.agencyCode))
		)
	LEFT JOIN CRM_CTL_Revenue DThu on DThu.IDHTTS=mt.IDHTTS and lower(mt.CTSoThucTe) = lower('DoanhThu') and 
		(
		 (mt.IDCoCau=0 and DThu.groupBy=3 and lower(npt.DB_UserName)=lower(DThu.salesmanEmail))
		 OR
		 (mt.IDCoCau>0 AND mt.IDCoCau>0 and DThu.groupBy in (1,2) and lower(ISNULL(cc.MaTichHop,cc.MaCoCau))=lower(DThu.agencyCode))
		)
	LEFT JOIN CRM_CTL_Customer KHang on KHang.IDHTTS=mt.IDHTTS and lower(mt.CTSoThucTe) = lower('KhachHangMoi') and 
		(
		 (mt.IDCoCau=0 and KHang.groupBy=3 and lower(npt.DB_UserName)=lower(KHang.salesmanEmail))
		 OR
		 (mt.IDCoCau>0 AND mt.IDCoCau>0 and KHang.groupBy in (1,2) and lower(ISNULL(cc.MaTichHop,cc.MaCoCau))=lower(KHang.agencyCode))
		)
	LEFT JOIN CRM_CTL_Customer_TuongTac KHangTT on KHangTT.IDHTTS=mt.IDHTTS and lower(mt.CTSoThucTe) = lower('KhachHangTuongTac') and 
		(
		 (mt.IDCoCau=0 and KHangTT.groupBy=3 and lower(npt.DB_UserName)=lower(KHangTT.salesmanEmail))
		 OR
		 (mt.IDCoCau>0 AND mt.IDCoCau>0 and KHangTT.groupBy in (1,2) and lower(ISNULL(cc.MaTichHop,cc.MaCoCau))=lower(KHangTT.agencyCode))
		)
	LEFT JOIN SYS_NhanSu nsd0 on nsd0.IDNhanSu=nkq.NguoiThuyetMinh
	LEFT JOIN SYS_NhanSu nsd1 on nsd1.IDNhanSu=nkq.NguoiDuyet1
	LEFT JOIN SYS_NhanSu nsd2 on nsd2.IDNhanSu=nkq.NguoiDuyet2
	LEFT JOIN SYS_NhanSu nsd3 on nsd3.IDNhanSu=nkq.NguoiDuyet3
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND mtts.IDCoCau=0 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0)
					AND (@CountKN=0 OR (@CountKN>0 AND ISNULL(mtts.IDChucDanh,0)=ISNULL(mt.IDChucDanh,0)))
				)
			)
	ORDER BY lmt.ThuTu, tmp.ThuTuCha, tmp.ThuTu,tmp.IDNhomMucTieu,tmp.STT;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuDanhGiaTongHop]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuDanhGiaTongHop]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint,
@IDCoCauPhuTrach bigint,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@DaDuyet bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @TMP_DanhGiaTongHop TABLE(IDDanhGia bigint NOT NULL,
										IDNhanSu bigint NOT NULL,
										IDCoCau bigint NOT NULL,
										IDChucDanh bigint NULL,
										MucDanhGia nvarchar(50) NULL,
										Diem decimal(9, 2) NULL,
										DiemCongTru decimal(9, 2) NULL,
										TongDiem decimal(9, 2) NULL,
										STT int,
										PRIMARY KEY (IDDanhGia,IDNhanSu,IDCoCau)
									);
	DECLARE @TMP_DanhGiaTongHopDiem TABLE(IDDanhGia bigint NOT NULL,
											IDLoaiMucTieu bigint NOT NULL,
											Diem decimal(9, 2) NULL,
											STT tinyint NULL,
											PRIMARY KEY (IDDanhGia,IDLoaiMucTieu)
										 );

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	DECLARE @TotalRow int;
	
	DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
	DECLARE @cnt int=1,@cnt_total int=0;

	IF @ChuThe = 0
	BEGIN--Theo bộ phận
		
		SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		IF @IDQuyen=1 OR @IDQuyen=2
		INSERT INTO @TableID (id) VALUES (@Q_IDCoCau);
		
		IF @IDQuyen=2 OR @IDQuyen=3
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
				
			--Them Chuc Danh kiem nhiem
			INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
			SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
			FROM SYS_NhanSu ns
			INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
			INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
			INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
			WHERE ns.IDNhanSu=@IDNhanSu;

			SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
			WHILE @cnt <= @cnt_total
			BEGIN
				SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
				IF @CayThuMuc IS NOT NULL 
					INSERT INTO @TableID (id) 
					SELECT cc.IDCoCau 
					from SYS_CoCau cc
					LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
					where cc.IDKhachHang=@IDKhachHang
					AND tmp.id is null
					and cc.CayThuMuc like @CayThuMuc+'%';
				SET @cnt = @cnt + 1;
			END;
		END;

		IF @IDQuyen=4
		BEGIN
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
		END;

		SELECT @TotalRow=COUNT(*)
		from SYS_CoCau cc 
		LEFT JOIN SYS_ChucDanh cd on cd.IDCoCau=cc.IDCoCau and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
		LEFT JOIN
					(SELECT ns.IDNhanSu, cd.IDCoCau,cd.IDChucDanh,ns.IDKhachHang, row_number() over (partition by cd.IDChucDanh order by cd.LaCapTruong desc) as STT
					FROM SYS_NhanSu ns
					INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
					WHERE ISNULL(ns.IsDelete,0)=0 and ISNULL(ns.TrangThai,0)=1
					AND ns.IDKhachHang=@IDKhachHang) ns 
					ON ns.IDCoCau=cc.IDCoCau and ns.IDChucDanh=cd.IDChucDanh and ns.IDKhachHang=cc.IDKhachHang and ns.STT=1
		INNER JOIN TW_HeThongMucTieu htmt on cc.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on cc.IDKhachHang=htmt.IDKhachHang and cc.IDCoCau=dg.IDCoCau AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS AND dg.IDNguoiPhuTrach<=0
		WHERE cc.IDKhachHang=@IDKhachHang
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND cc.IDCoCau in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (cc.IDCoCau in (select id from @TableID) OR ns.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		AND ISNULL(cc.IsDelete,0)=0
		AND ISNULL(cc.SuDung,0)=1
		and htmt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IDCoCau IS NULL OR cc.CayThuMuc like '%;' + cast(@IDCoCau as varchar(20)) + ';%');

		INSERT INTO @TMP_DanhGiaTongHop (IDNhanSu,IDDanhGia,IDChucDanh,IDCoCau,MucDanhGia,Diem,DiemCongTru,TongDiem,STT)
		SELECT ISNULL(ns.IDNhanSu,0),ISNULL(dg.IDDanhGia,0),cd.IDChucDanh,cc.IDCoCau,dg.MaMucDanhGia,dg.Diem,dg.DiemCongTru,dg.TongDiem,
				row_number() over (order by cc.MaThuMuc) as STT
		from SYS_CoCau cc 
		LEFT JOIN
					(SELECT ns.IDNhanSu, cd.IDCoCau,cd.IDChucDanh,ns.IDKhachHang, row_number() over (partition by cd.IDChucDanh order by cd.LaCapTruong desc) as STT
					FROM SYS_NhanSu ns
					INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1
					WHERE ISNULL(ns.IsDelete,0)=0 and ISNULL(ns.TrangThai,0)=1
					AND ns.IDKhachHang=@IDKhachHang) ns 
					ON ns.IDCoCau=cc.IDCoCau and ns.IDKhachHang=cc.IDKhachHang and ns.STT=1
		LEFT JOIN SYS_ChucDanh cd on cd.IDCoCau=cc.IDCoCau and ISNULL(cd.IsDelete,0)=0 and ISNULL(cd.LaCapTruong,0)=1 AND ns.IDChucDanh=cd.IDChucDanh
		INNER JOIN TW_HeThongMucTieu htmt on cc.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on cc.IDKhachHang=htmt.IDKhachHang and cc.IDCoCau=dg.IDCoCau AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS AND dg.IDNguoiPhuTrach<=0
		--LEFT JOIN TW_LoaiMucTieuKetQua lmtkq on lmtkq.IDDanhGia=dg.IDDanhGia AND lmtkq.IDLoaiMucTieu=@IDXepHang
		WHERE cc.IDKhachHang=@IDKhachHang
		AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(
					(@IDQuyen=1 AND cc.IDCoCau in (select id from @TableID))
					OR (@IDQuyen in (2,3,4) AND (cc.IDCoCau in (select id from @TableID) OR ns.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
				)
			)
		)
		AND ISNULL(cc.IsDelete,0)=0
		AND ISNULL(cc.SuDung,0)=1
		and htmt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IDCoCau IS NULL OR cc.CayThuMuc like '%;' + cast(@IDCoCau as varchar(20)) + ';%')
		ORDER BY cc.MaThuMuc
		OFFSET (@PageIndex - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;

		--Lay DiemHoanThanh
		INSERT INTO @TMP_DanhGiaTongHopDiem
		(IDDanhGia,IDLoaiMucTieu,Diem,STT)
		SELECT lmtkq.IDDanhGia,lmtkq.IDLoaiMucTieu,lmtkq.DiemHoanThanh,lmt.STT
		FROM TW_LoaiMucTieuKetQua lmtkq
		INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=lmtkq.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
		WHERE IDDanhGia in (SELECT IDDanhGia FROM @TMP_DanhGiaTongHop);
		

		SELECT tmp.*, @TotalRow as TotalRow, ISNULL(dgth.Khoa,dg.Khoa) as Khoa,dgth.MucDuyet,dgth.DiemDuyet,dgth.NhanXet,ns.MaNhanSu, ns.HoVaTen, ns.TenNhanSuNgan, ns.AnhNhanSu,cc.MaCoCau, cc.TenCoCau,cc.TenCoCauNgan,cc.CoLopCon,cc.STT,cc.CapBac,cd.MaChucDanh,cd.TenChucDanh, cd.TenChucDanhNgan,
		d1.Diem as Diem1,
		d2.Diem as Diem2,
		d3.Diem as Diem3,
		d4.Diem as Diem4,
		d5.Diem as Diem5,
		d6.Diem as Diem6,
		d7.Diem as Diem7,
		d8.Diem as Diem8,
		d9.Diem as Diem9,
		d10.Diem as Diem10,
		mdg1.MauSac as MauSac1,
		mdg2.MauSac as MauSac2
		FROM @TMP_DanhGiaTongHop tmp
		LEFT JOIN SYS_NhanSu ns on ns.IDNhanSu=tmp.IDNhanSu
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=tmp.IDCoCau
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=tmp.IDChucDanh
		LEFT JOIN TW_DanhGiaTongHop dgth on tmp.IDDanhGia=dgth.IDDanhGia
		LEFT JOIN TW_DanhGia dg on tmp.IDDanhGia=dg.IDDanhGia
		LEFT JOIN @TMP_DanhGiaTongHopDiem d1 on d1.IDDanhGia=tmp.IDDanhGia and d1.STT=1
		LEFT JOIN @TMP_DanhGiaTongHopDiem d2 on d2.IDDanhGia=tmp.IDDanhGia and d2.STT=2
		LEFT JOIN @TMP_DanhGiaTongHopDiem d3 on d3.IDDanhGia=tmp.IDDanhGia and d3.STT=3
		LEFT JOIN @TMP_DanhGiaTongHopDiem d4 on d4.IDDanhGia=tmp.IDDanhGia and d4.STT=4
		LEFT JOIN @TMP_DanhGiaTongHopDiem d5 on d5.IDDanhGia=tmp.IDDanhGia and d5.STT=5
		LEFT JOIN @TMP_DanhGiaTongHopDiem d6 on d6.IDDanhGia=tmp.IDDanhGia and d6.STT=6
		LEFT JOIN @TMP_DanhGiaTongHopDiem d7 on d7.IDDanhGia=tmp.IDDanhGia and d7.STT=7
		LEFT JOIN @TMP_DanhGiaTongHopDiem d8 on d8.IDDanhGia=tmp.IDDanhGia and d8.STT=8
		LEFT JOIN @TMP_DanhGiaTongHopDiem d9 on d9.IDDanhGia=tmp.IDDanhGia and d9.STT=9
		LEFT JOIN @TMP_DanhGiaTongHopDiem d10 on d10.IDDanhGia=tmp.IDDanhGia and d10.STT=10
		LEFT JOIN TW_MucDanhGia mdg1 on mdg1.IDKhachHang=@IDKhachHang AND ISNULL(mdg1.IsDelete,0)=0 AND UPPER(mdg1.MaMucDanhGia)=UPPER(tmp.MucDanhGia) AND mdg1.IDChuThe=0 
		LEFT JOIN TW_MucDanhGia mdg2 on mdg2.IDKhachHang=@IDKhachHang AND ISNULL(mdg2.IsDelete,0)=0 AND UPPER(mdg2.MaMucDanhGia)=UPPER(dgth.MucDuyet) AND mdg2.IDChuThe=0
		ORDER BY tmp.STT;
	END;
	ELSE
	BEGIN--Theo Nhân sự
		
		SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		IF @IDQuyen=1
		INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
		IF @IDQuyen=2 OR @IDQuyen=3
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
	
			--Them Chuc Danh kiem nhiem
			INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
			SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
			FROM SYS_NhanSu ns
			INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
			INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
			INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
			WHERE ns.IDNhanSu=@IDNhanSu;

			SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
			WHILE @cnt <= @cnt_total
			BEGIN
				SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
				IF @CayThuMuc IS NOT NULL 
					INSERT INTO @TableID (id) 
					SELECT cc.IDCoCau 
					from SYS_CoCau cc
					LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
					where cc.IDKhachHang=@IDKhachHang
					AND tmp.id is null
					and cc.CayThuMuc like @CayThuMuc+'%';
				SET @cnt = @cnt + 1;
			END;
		END;

		IF @IDQuyen=4
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
		END;

		SELECT @TotalRow=COUNT(*)
		FROM SYS_NhanSu ns
		INNER JOIN TW_HeThongMucTieu htmt on ns.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on ns.IDKhachHang=htmt.IDKhachHang and ns.IDNhanSu=dg.IDNguoiPhuTrach AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS AND dg.IDCoCau<=0
		--Kiểm tra Quyền theo setting
		LEFT JOIN @TableID Q1 ON (@IDQuyen=5
			OR (@IDQuyen=1 AND ns.IDNhanSu=Q1.id)
			OR (@IDQuyen in (2,3,4) AND (ns.IDCoCau=Q1.id))
			)
		WHERE ns.IDKhachHang=@IDKhachHang
		AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
		and htmt.IDHTMT=@IDHTMT
		AND ISNULL(ns.IsDelete,0)=0
		AND ns.TrangThai=1
		AND (@IDCoCauPhuTrach Is null OR (@IDCoCauPhuTrach is not null and ns.IDCoCau = @IDCoCauPhuTrach))
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ns.IDNhanSu = @IDNguoiPhuTrach))

		INSERT INTO @TMP_DanhGiaTongHop (IDNhanSu,IDDanhGia,IDChucDanh,IDCoCau,MucDanhGia,Diem,DiemCongTru,TongDiem,STT)
		SELECT ns.IDNhanSu,ISNULL(dg.IDDanhGia,0),
		(CASE WHEN ISNULL(dg.IDChucDanh,0)>0 THEN dg.IDChucDanh 
			ELSE ns.IDChucDanh END
		) as IDChucDanh,
		ISNULL(ns.IDCoCau,0),dg.MaMucDanhGia,dg.Diem,dg.DiemCongTru,dg.TongDiem, row_number() over (order by cc.MaThuMuc, ns.MaNhanSu,ISNULL(ttcd.iskiemnhiem,9),cd.MaThuMuc) as STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=ns.IDCoCau
		INNER JOIN SYS_ChucDanh cd on cd.IDChucDanh=ns.IDChucDanh
		INNER JOIN TW_HeThongMucTieu htmt on ns.IDKhachHang=htmt.IDKhachHang and htmt.IDHTMT=@IDHTMT
		LEFT JOIN TW_DanhGia dg on ns.IDKhachHang=htmt.IDKhachHang and ns.IDNhanSu=dg.IDNguoiPhuTrach AND dg.IDHTMT=@IDHTMT AND dg.IDHTTS = @IDHTTS AND dg.IDCoCau<=0
		LEFT JOIN TW_TyTrongChucDanh ttcd on ttcd.IDHTMT=dg.IDHTMT and ttcd.IDHTTS=dg.IDHTTS and ttcd.IDNhanSu=dg.IDNguoiPhuTrach and ttcd.IDChucDanh=dg.IDChucDanh
		WHERE ns.IDKhachHang=@IDKhachHang
		AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND ns.IDNhanSu in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (ns.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
		)
		and htmt.IDHTMT=@IDHTMT
		AND ISNULL(ns.IsDelete,0)=0
		AND ns.TrangThai=1
		AND (@IDCoCauPhuTrach Is null OR (@IDCoCauPhuTrach is not null and ns.IDCoCau = @IDCoCauPhuTrach))
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and ns.IDNhanSu = @IDNguoiPhuTrach))
		ORDER BY cc.MaThuMuc, cd.MaThuMuc, ns.MaNhanSu
		OFFSET (@PageIndex - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;

		--Lay DiemHoanThanh
		INSERT INTO @TMP_DanhGiaTongHopDiem
		(IDDanhGia,IDLoaiMucTieu,Diem,STT)
		SELECT lmtkq.IDDanhGia,lmtkq.IDLoaiMucTieu,lmtkq.DiemHoanThanh,lmt.STT
		FROM TW_LoaiMucTieuKetQua lmtkq
		INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=lmtkq.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
		WHERE IDDanhGia in (SELECT IDDanhGia FROM @TMP_DanhGiaTongHop);
		
		SELECT tmp.*
		, @TotalRow as TotalRow,ISNULL(dgth.Khoa,dg.Khoa) as Khoa, dgth.MucDuyet,dgth.DiemDuyet,dgth.NhanXet,ns.MaNhanSu, ns.HoVaTen, ns.TenNhanSuNgan, ns.AnhNhanSu,cc.MaCoCau, cc.TenCoCau,cc.TenCoCauNgan,cc.CoLopCon,cc.STT,cc.CapBac,
		cd.MaChucDanh,cd.TenChucDanh,
		d1.Diem as Diem1,
		d2.Diem as Diem2,
		d3.Diem as Diem3,
		d4.Diem as Diem4,
		d5.Diem as Diem5,
		d6.Diem as Diem6,
		d7.Diem as Diem7,
		d8.Diem as Diem8,
		d9.Diem as Diem9,
		d10.Diem as Diem10,
		mdg1.MauSac as MauSac1,
		mdg2.MauSac as MauSac2
		FROM @TMP_DanhGiaTongHop tmp
		LEFT JOIN SYS_NhanSu ns on ns.IDNhanSu=tmp.IDNhanSu
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=ns.IDCoCau
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=tmp.IDChucDanh
		LEFT JOIN TW_DanhGiaTongHop dgth on tmp.IDDanhGia=dgth.IDDanhGia
		LEFT JOIN TW_DanhGia dg on tmp.IDDanhGia=dg.IDDanhGia
		LEFT JOIN @TMP_DanhGiaTongHopDiem d1 on d1.IDDanhGia=tmp.IDDanhGia and d1.STT=1
		LEFT JOIN @TMP_DanhGiaTongHopDiem d2 on d2.IDDanhGia=tmp.IDDanhGia and d2.STT=2
		LEFT JOIN @TMP_DanhGiaTongHopDiem d3 on d3.IDDanhGia=tmp.IDDanhGia and d3.STT=3
		LEFT JOIN @TMP_DanhGiaTongHopDiem d4 on d4.IDDanhGia=tmp.IDDanhGia and d4.STT=4
		LEFT JOIN @TMP_DanhGiaTongHopDiem d5 on d5.IDDanhGia=tmp.IDDanhGia and d5.STT=5
		LEFT JOIN @TMP_DanhGiaTongHopDiem d6 on d6.IDDanhGia=tmp.IDDanhGia and d6.STT=6
		LEFT JOIN @TMP_DanhGiaTongHopDiem d7 on d7.IDDanhGia=tmp.IDDanhGia and d7.STT=7
		LEFT JOIN @TMP_DanhGiaTongHopDiem d8 on d8.IDDanhGia=tmp.IDDanhGia and d8.STT=8
		LEFT JOIN @TMP_DanhGiaTongHopDiem d9 on d9.IDDanhGia=tmp.IDDanhGia and d9.STT=9
		LEFT JOIN @TMP_DanhGiaTongHopDiem d10 on d10.IDDanhGia=tmp.IDDanhGia and d10.STT=10
		LEFT JOIN TW_MucDanhGia mdg1 on mdg1.IDKhachHang=@IDKhachHang AND ISNULL(mdg1.IsDelete,0)=0 AND UPPER(mdg1.MaMucDanhGia)=UPPER(tmp.MucDanhGia) AND mdg1.IDChuThe=1 
		LEFT JOIN TW_MucDanhGia mdg2 on mdg2.IDKhachHang=@IDKhachHang AND ISNULL(mdg2.IsDelete,0)=0 AND UPPER(mdg2.MaMucDanhGia)=UPPER(dgth.MucDuyet) AND mdg2.IDChuThe=1
		ORDER BY tmp.STT;
	END;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuDanhGiaTongHopLuong]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuDanhGiaTongHopLuong]
@Year int,
@TuNgay date,
@DenNgay date,
@IDLoaiTanSuat tinyint,--1 Năm, 2 Nửa năm, 3 Quý, 4 Tháng
@ChuThe tinyint,
@UserName varchar(200),
@IDChucNang int
AS
BEGIN
	DECLARE @Error int=0;
	DECLARE @IDKhachHang int;
	DECLARE @IDNhanSu bigint;
	DECLARE @TableID TABLE(id bigint NOT NULL);

	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;
	SELECT @IDNhanSu=IDNhanSu, @IDKhachHang=IDKhachHang, @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE lower(DB_UserName)=lower(@UserName) and DB_UserName is not null ;

	IF @IDNhanSu IS NULL
	BEGIN
		SELECT -1 as Error;
		RETURN;
	END;

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TMP_DanhGiaTongHop TABLE(IDDanhGia bigint NOT NULL,
										IDHTMT	bigint,
										IDHTTS bigint,
										IDNhanSu bigint NOT NULL,
										IDCoCau bigint NOT NULL,
										MucDanhGia nvarchar(50) NULL,
										DiemTong decimal(9, 2) NULL,
										DB_IDCoCau	bigint NULL,
										DB_IDNhanSu	bigint NULL,
										PRIMARY KEY (IDDanhGia,IDNhanSu,IDCoCau)
									);

	DECLARE @TMP_DanhGiaTongHopDiem TABLE(IDCoCau bigint NOT NULL,
											IDNhanSu bigint NOT NULL,
											IDLoaiMucTieu bigint NOT NULL,
											Diem decimal(9, 2) NULL,
											STT tinyint NULL,
											PRIMARY KEY (IDCoCau,IDNhanSu,IDLoaiMucTieu)
										 );

	IF @ChuThe = 0
	BEGIN--Theo bộ phận
		
		SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		IF @IDQuyen=1 OR @IDQuyen=2
		INSERT INTO @TableID (id) VALUES (@Q_IDCoCau);
		
		IF @IDQuyen=2 OR @IDQuyen=3
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
		END;

		IF @IDQuyen=4
		BEGIN
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
		END;

		INSERT INTO @TMP_DanhGiaTongHop (IDDanhGia,IDHTMT,IDHTTS,IDNhanSu,IDCoCau,MucDanhGia,DiemTong,DB_IDCoCau)
		SELECT dg.IDDanhGia,htts.IDHTMT,htts.IDHTTS,dg.IDNguoiPhuTrach,dg.IDCoCau,ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) AS MucDanhGia, ISNULL(dgth.DiemDuyet,ISNULL(dg.Diem,0)) as Diem,cc.DB_IDCoCau
		FROM SYS_CoCau cc
		INNER JOIN TW_NamTaiChinh ntc on ntc.IDKhachHang=@IDKhachHang and ntc.Nam=@Year and ISNULL(ntc.IsDelete,0)=0
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDKhachHang=@IDKhachHang and ISNULL(htmt.IsDelete,0)=0 and htmt.IDNamTaiChinh=IDNamTaiChinh
		INNER JOIN TW_HeThongTanSuat htts on htts.IDHTMT=htmt.IDHTMT and htts.IDLoaiTanSuat=@IDLoaiTanSuat and htts.BatDau=@TuNgay AND htts.KetThuc=@DenNgay
		INNER JOIN TW_DanhGia dg on dg.IDCoCau=cc.IDCoCau
									and dg.IDHTMT=htmt.IDHTMT
									and dg.IDHTTS=htts.IDHTTS 
									and dg.IDCoCau>0
									and dg.IDChucDanh=0
									and ISNULL(dg.Khoa,0)=1
		LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia
		--Kiểm tra Quyền theo setting
		LEFT JOIN @TableID Q1 ON (@IDQuyen=5
			OR (@IDQuyen in (1,2,3,4) AND (cc.IDCoCau=Q1.id))
			)
		WHERE ISNULL(cc.IsDelete,0)=0
		AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
		AND cc.IDKhachHang=@IDKhachHang
		AND dg.Diem is not null
		
		--ORDER BY CayThuMuc

		DELETE FROM @TMP_DanhGiaTongHopDiem WHERE Diem is null;
		
		SELECT @Error as Error,
		tmp.DB_IDCoCau as ID,
		tmp.DiemTong,
		tmp.MucDanhGia
		FROM @TMP_DanhGiaTongHop tmp;
	END;
	ELSE
	BEGIN--Theo Nhân sự
		
		SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
		IF @IDQuyen=1
		INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
		IF @IDQuyen=2 OR @IDQuyen=3
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
		END;

		IF @IDQuyen=4
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
			INSERT INTO @TableID (id)
			SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
		END;

		INSERT INTO @TMP_DanhGiaTongHop (IDDanhGia,IDHTMT,IDHTTS,IDNhanSu,IDCoCau,MucDanhGia,DiemTong,DB_IDNhanSu)
		SELECT dg.IDDanhGia,htts.IDHTMT,htts.IDHTTS,dg.IDNguoiPhuTrach,dg.IDCoCau,ISNULL(dgth.MucDuyet,dg.MaMucDanhGia) AS MucDanhGia, ISNULL(dgth.DiemDuyet,ISNULL(dg.Diem,0)) as Diem,ns.DB_IDNhanSu
		FROM SYS_NhanSu ns
		INNER JOIN TW_NamTaiChinh ntc on ntc.IDKhachHang=@IDKhachHang and ntc.Nam=@Year and ISNULL(ntc.IsDelete,0)=0
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDKhachHang=@IDKhachHang and ISNULL(htmt.IsDelete,0)=0 and htmt.IDNamTaiChinh=IDNamTaiChinh
		INNER JOIN TW_HeThongTanSuat htts on htts.IDHTMT=htmt.IDHTMT and htts.IDLoaiTanSuat=@IDLoaiTanSuat and htts.BatDau=@TuNgay AND htts.KetThuc=@DenNgay
		INNER JOIN TW_DanhGia dg on dg.IDNguoiPhuTrach=ns.IDNhanSu
									and dg.IDHTMT=htmt.IDHTMT
									and dg.IDHTTS=htts.IDHTTS 
									and dg.IDNguoiPhuTrach>0
									and dg.IDChucDanh=0
									and ISNULL(dg.Khoa,0)=1
		LEFT JOIN TW_DanhGiaTongHop dgth on dgth.IDDanhGia=dg.IDDanhGia
		--Kiểm tra Quyền theo setting
		LEFT JOIN @TableID Q1 ON (@IDQuyen=5
			OR (@IDQuyen=1 AND ns.IDNhanSu=Q1.id)
			OR (@IDQuyen in (2,3,4) AND (ns.IDCoCau=Q1.id))
			)
		WHERE ISNULL(ns.IsDelete,0)=0
		AND (@IDQuyen=5 OR (@IDQuyen!=5 AND Q1.id is not null))
		AND ns.IDKhachHang=@IDKhachHang
		AND dg.Diem is not null;
		--ORDER BY CayThuMuc
		
		DELETE FROM @TMP_DanhGiaTongHopDiem WHERE Diem is null;
		
		SELECT @Error as Error,
		tmp.DB_IDNhanSu as ID,
		tmp.DiemTong,
		tmp.MucDanhGia
		FROM @TMP_DanhGiaTongHop tmp;
	END;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuDuyetCha]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuDuyetCha]
@IDHTMT	bigint = null,
@IDCha bigint=null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@IDTrangThaiDuyet tinyint=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDChucDanh bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@IDCapDuyet int,
@IDTrangThaiCapDuyet int,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN

	DECLARE @TMP_MucTieu TABLE( IDNhomMucTieu bigint NOT NULL,
								IDMucTieu bigint NOT NULL,
								IDKhachHang int NOT NULL,
								STT int NULL,
								TenMucTieu nvarchar(2000) NULL,
								MaMucTieu nvarchar(100) NULL,
								TrongSoPT decimal(13, 5) NULL,
								IDCoCau bigint NULL,
								IDNguoiPhuTrach bigint NULL,
								ThuTu smallint NULL,
								ThuTuCha smallint NULL,
								CapBacNhom tinyint NULL,
								PRIMARY KEY (IDNhomMucTieu, IDMucTieu)
							  );

	--@ChuThe: 0-Tổ chức, 1-Cá nhân
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (@IDCoCau IS NULL AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
	END;

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	--1: nhân sự, 2: Quản lý, 3: Bộ phận, 4: Chỉ định BP, 5: Toàn quyền
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4--Khong xem BP con
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);
	
	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND mt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
		AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
		AND ( 
			(@IDCapDuyet=1 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet1,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=2 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet2,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=3 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet3,0) = @IDTrangThaiDuyet))
		)
		AND (@IDTrangThaiCapDuyet is null or mt.IDTrangThaiDuyet=@IDTrangThaiCapDuyet)
		AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
		AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	DECLARE @CountKN int=0;
	SELECT @CountKN=COUNT(*) 
		FROM TW_TyTrongChucDanh ttcd
		LEFT JOIN SYS_NhanSu ns on ns.IDChucDanh=ttcd.IDChucDanh and ns.IDNhanSu=ttcd.IDNhanSu
		WHERE ttcd.IDHTMT=@IDHTMT 
			and ttcd.IDHTTS=@IDHTTS 
			and ttcd.IDNhanSu=@IDNguoiPhuTrach 
			and ISNULL(ttcd.TyTrong,0)>0
			AND ns.IDNhanSu is null;

	DECLARE @TotalRow int;

	SELECT @TotalRow=COUNT(*)
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0)
					AND (@CountKN=0 OR (@CountKN>0 AND ISNULL(mtts.IDChucDanh,0)=ISNULL(mt.IDChucDanh,0)))
				)
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND ( 
			(@IDCapDuyet=1 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet1,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=2 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet2,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=3 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet3,0) = @IDTrangThaiDuyet))
		)
	AND (@IDTrangThaiCapDuyet is null or mt.IDTrangThaiDuyet=@IDTrangThaiCapDuyet)
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'));

	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,TrongSoPT,IDKhachHang,IDCoCau,STT,ThuTu,ThuTuCha,CapBacNhom)
	SELECT mt.IDNhomMucTieu, mt.IDMucTieu,mt.MaMucTieu,mt.TenMucTieu,mtts.TrongSoPT,htmt.IDKhachHang,mt.IDCoCau,ROW_NUMBER() OVER (ORDER BY lmt.ThuTu,nmt.ThuTuCha, nmt.ThuTu,nmt.CapBac, mt.MaThuMuc) AS STT,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0)
					AND (@CountKN=0 OR (@CountKN>0 AND ISNULL(mtts.IDChucDanh,0)=ISNULL(mt.IDChucDanh,0)))
				)
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND ( 
			(@IDCapDuyet=1 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet1,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=2 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet2,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=3 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet3,0) = @IDTrangThaiDuyet))
		)
	AND (@IDTrangThaiCapDuyet is null or mt.IDTrangThaiDuyet=@IDTrangThaiCapDuyet)
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY STT
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
	
	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom,TrongSoPT)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,nmt.MaNhomMucTieu as MaMucTieu,nmt.TenNhomMucTieu as TenMucTieu,@IDKhachHang,0,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac,nmtts.TrongSoPT
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_DanhGia dg on dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS and dg.IDCoCau=ISNULL(@IDCoCau,0) and dg.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and dg.IDChucDanh=ISNULL(@IDChucDanh,0)
	LEFT JOIN TW_NhomMucTieuTrongSo nmtts on nmtts.IDDanhGia=dg.IDDanhGia and nmtts.IDNhomMucTieu=nmt.IDNhomMucTieu
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)>0 and ISNULL(nmt.SuDung,0)=1
	AND nmt.IDNhomMucTieu IN (SELECT distinct IDNhomMucTieu FROM @TMP_MucTieu)

	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom,TrongSoPT)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,nmt.MaNhomMucTieu as MaMucTieu,nmt.TenNhomMucTieu as TenMucTieu,@IDKhachHang,0,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac,nmtts.TrongSoPT
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_DanhGia dg on dg.IDHTMT=@IDHTMT and dg.IDHTTS=@IDHTTS and dg.IDCoCau=ISNULL(@IDCoCau,0) and dg.IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0) and dg.IDChucDanh=isnull(@IDChucDanh,0)
	LEFT JOIN TW_NhomMucTieuTrongSo nmtts on nmtts.IDDanhGia=dg.IDDanhGia and nmtts.IDNhomMucTieu=nmt.IDNhomMucTieu
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)=0 and ISNULL(nmt.SuDung,0)=1
	AND (
			nmt.IDNhomMucTieu in  (SELECT IDNhomMucTieu from @TMP_MucTieu tmp WHERE tmp.IDMucTieu>0)
			OR
			nmt.IDNhomMucTieu in  (SELECT nmt.IDCha from @TMP_MucTieu tmp 
								INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu
								WHERE tmp.IDMucTieu<0)
		)

	--Kiểm tra nhóm mục tiêu
	DECLARE @CountNhom int=0;
	SELECT @CountNhom=COUNT(*) FROM @TMP_MucTieu WHERE IDMucTieu<0;
	IF(@CountNhom=0)
	BEGIN
		INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom)
		VALUES (0, 0-@TotalRow,'','',@IDKhachHang,0,0,0,0)
	END;

	SELECT tmp.*,ISNULL(mt.IDTrangThaiDuyet,0) as IDTrangThaiDuyet,ISNULL(mt.IDTrangThaiDuyet1,0) as IDTrangThaiDuyet1,ISNULL(mt.IDTrangThaiDuyet2,0) as IDTrangThaiDuyet2,ISNULL(mt.IDTrangThaiDuyet3,0) as IDTrangThaiDuyet3,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,mt.TrongSo,ccpt.TenCoCau as TenCoCauPT,ccpt.TenCoCauNgan as TenCoCauNganPT,
	ttmt.TenTrangThaiMucTieu, lts.TenLoaiTanSuat, npt.HoVaTen as TenNguoiPhuTrach, npt.TenNhanSuNgan, cd.TenChucDanh,cd.TenChucDanhNgan, cc.TenCoCau,cc.TenCoCauNgan, mt.KyHan,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	mt.NgayHoanThanh,round(ISNULL(mt.TyLeHoanThanh,mt.TyLeTamTinh),1) as TyLeHoanThanh,round(mt.DiemHoanThanh,2) as DiemHoanThanh,npt.AnhNhanSu,
	ISNULL(mt.CapBac,0) as CapBac,ISNULL(mt.CoLopCon,0) as CoLopCon, htts.TenTanSuat as KyDanhGia,
	mt.PhanHoi1,mt.PhanHoi2,mt.PhanHoi3,
	nsd1.MaNhanSu +' - '+ nsd1.HoVaTen as TenNguoiDuyet1,
	nsd2.MaNhanSu +' - '+ nsd2.HoVaTen as TenNguoiDuyet2,
	nsd3.MaNhanSu +' - '+ nsd3.HoVaTen as TenNguoiDuyet3,
	FORMAT(mt.NgayDuyet1, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet1,
	FORMAT(mt.NgayDuyet2, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet2,
	FORMAT(mt.NgayDuyet3, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet3
	FROM @TMP_MucTieu tmp
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieu mt on mt.IDMucTieu=tmp.IDMucTieu AND mt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=tmp.IDMucTieu
	LEFT JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=mt.IDHTMT and htts.IDHTTS=mt.IDHTTS and htts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=cc.IDNhomCap and nc.IDKhachHang=@IDKhachHang
	LEFT JOIN ENUM_TrangThaiMucTieu ttmt on ttmt.IDTrangThaiMucTieu=mt.IDTrangThaiMucTieu
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN SYS_NhanSu nsd1 on nsd1.IDNhanSu=mt.NguoiDuyet1
	LEFT JOIN SYS_NhanSu nsd2 on nsd2.IDNhanSu=mt.NguoiDuyet2
	LEFT JOIN SYS_NhanSu nsd3 on nsd3.IDNhanSu=mt.NguoiDuyet3
	ORDER BY lmt.ThuTu, tmp.ThuTuCha, tmp.ThuTu,tmp.IDNhomMucTieu,tmp.STT;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuDuyetCon]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuDuyetCon]
@IDHTMT	bigint = null,
@IDCha bigint=null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@IDTrangThaiDuyet tinyint=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDChucDanh bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@IDCapDuyet int,
@IDTrangThaiCapDuyet int,
@PageSize int = 1000, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN

	DECLARE @TMP_MucTieu TABLE( IDNhomMucTieu bigint NOT NULL,
								IDMucTieu bigint NOT NULL,
								IDKhachHang int NOT NULL,
								STT int NULL,
								TenMucTieu nvarchar(2000) NULL,
								MaMucTieu nvarchar(100) NULL,
								TrongSoPT decimal(13, 5) NULL,
								IDCoCau bigint NULL,
								IDNguoiPhuTrach bigint NULL,
								ThuTu smallint NULL,
								ThuTuCha smallint NULL,
								CapBacNhom tinyint NULL,
								PRIMARY KEY (IDNhomMucTieu, IDMucTieu)
							  );
	--@ChuThe: 0-Tổ chức, 1-Cá nhân
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (@IDCoCau IS NULL AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
	END;

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);
	
	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND mt.IDHTMT=@IDHTMT
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
		AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
		AND ( 
			(@IDCapDuyet=1 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet1,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=2 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet2,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=3 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet3,0) = @IDTrangThaiDuyet))
		)
		AND (@IDTrangThaiCapDuyet is null or mt.IDTrangThaiDuyet=@IDTrangThaiCapDuyet)
		AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
		AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	DECLARE @CountKN int=0;
	SELECT @CountKN=COUNT(*) 
		FROM TW_TyTrongChucDanh ttcd
		LEFT JOIN SYS_NhanSu ns on ns.IDChucDanh=ttcd.IDChucDanh and ns.IDNhanSu=ttcd.IDNhanSu
		WHERE ttcd.IDHTMT=@IDHTMT 
			and ttcd.IDHTTS=@IDHTTS 
			and ttcd.IDNhanSu=@IDNguoiPhuTrach 
			and ISNULL(ttcd.TyTrong,0)>0
			AND ns.IDNhanSu is null;

	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,IDCoCau,STT)
	SELECT mt.IDNhomMucTieu, mt.IDMucTieu,mt.MaMucTieu,mt.TenMucTieu,htmt.IDKhachHang,mt.IDCoCau,ROW_NUMBER() OVER (ORDER BY lmt.ThuTu,nmt.ThuTuCha, nmt.ThuTu,nmt.CapBac, mt.MaThuMuc) AS STT 
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0)
					AND (@CountKN=0 OR (@CountKN>0 AND ISNULL(mtts.IDChucDanh,0)=ISNULL(mt.IDChucDanh,0)))
				)
			)
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND ISNULL(mt.IDMucTieuCha,0) = ISNULL(@IDCha,0)
	AND mt.IDHTMT=@IDHTMT
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND ( 
			(@IDCapDuyet=1 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet1,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=2 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet2,0) = @IDTrangThaiDuyet))
			OR (@IDCapDuyet=3 and (@IDTrangThaiDuyet Is null OR ISNULL(mt.IDTrangThaiDuyet3,0) = @IDTrangThaiDuyet))
		)
	AND (@IDTrangThaiCapDuyet is null or mt.IDTrangThaiDuyet=@IDTrangThaiCapDuyet)
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	--AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY STT
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
	
	SELECT tmp.*, ISNULL(mt.IDTrangThaiDuyet,0) as IDTrangThaiDuyet,ISNULL(mt.IDTrangThaiDuyet1,0) as IDTrangThaiDuyet1,ISNULL(mt.IDTrangThaiDuyet2,0) as IDTrangThaiDuyet2,ISNULL(mt.IDTrangThaiDuyet3,0) as IDTrangThaiDuyet3,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,mt.TrongSo,ccpt.TenCoCau as TenCoCauPT,ccpt.TenCoCauNgan as TenCoCauNganPT,
	ttmt.TenTrangThaiMucTieu, lts.TenLoaiTanSuat, npt.HoVaTen as TenNguoiPhuTrach, npt.TenNhanSuNgan, cd.TenChucDanh,cd.TenChucDanhNgan, cc.TenCoCau,cc.TenCoCauNgan, mt.KyHan,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	mt.NgayHoanThanh,round(ISNULL(mt.TyLeHoanThanh,mt.TyLeTamTinh),1) as TyLeHoanThanh,round(mt.DiemHoanThanh,2) as DiemHoanThanh,npt.AnhNhanSu,
	ISNULL(mt.CapBac,0) as CapBac,ISNULL(mt.CoLopCon,0) as CoLopCon, htts.TenTanSuat as KyDanhGia,
	mt.PhanHoi1,mt.PhanHoi2,mt.PhanHoi3,
	nsd1.MaNhanSu +' - '+ nsd1.HoVaTen as TenNguoiDuyet1,
	nsd2.MaNhanSu +' - '+ nsd2.HoVaTen as TenNguoiDuyet2,
	nsd3.MaNhanSu +' - '+ nsd3.HoVaTen as TenNguoiDuyet3,
	FORMAT(mt.NgayDuyet1, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet1,
	FORMAT(mt.NgayDuyet2, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet2,
	FORMAT(mt.NgayDuyet3, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet3
	FROM @TMP_MucTieu tmp
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieu mt on mt.IDMucTieu=tmp.IDMucTieu AND mt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=tmp.IDMucTieu
	LEFT JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=mt.IDHTMT and htts.IDHTTS=mt.IDHTTS and htts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=cc.IDNhomCap and nc.IDKhachHang=@IDKhachHang
	LEFT JOIN ENUM_TrangThaiMucTieu ttmt on ttmt.IDTrangThaiMucTieu=mt.IDTrangThaiMucTieu
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN SYS_NhanSu nsd1 on nsd1.IDNhanSu=mt.NguoiDuyet1
	LEFT JOIN SYS_NhanSu nsd2 on nsd2.IDNhanSu=mt.NguoiDuyet2
	LEFT JOIN SYS_NhanSu nsd3 on nsd3.IDNhanSu=mt.NguoiDuyet3
	ORDER BY lmt.ThuTu, tmp.ThuTuCha, tmp.ThuTu,tmp.IDNhomMucTieu,tmp.STT;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuNhapKetQua]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuNhapKetQua]
@IDHTMT	bigint = null,
@IDCha bigint=null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@DaDuyet bit=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @TMP_MucTieuNhapKetQua TABLE(IDNhomMucTieu bigint NOT NULL,
										IDMucTieu bigint NOT NULL,
										IDKhachHang int NOT NULL,
										STT int NULL,
										TenMucTieu nvarchar(2000) NULL,
										MaMucTieu nvarchar(100) NULL,
										IDNguoiPhuTrach bigint NULL,
										IDChucDanh bigint NULL,
										IDCoCau bigint NULL,
										SoKeHoachSo decimal(18, 2) NULL,
										SoKeHoachNgay date NULL,
										SoKeHoachTyLe decimal(7, 2) NULL,
										IDDonViTinh bigint NULL,
										CoLopCon bit NULL,
										CapBac tinyint NULL,
										CayThuMuc nvarchar(256) NULL,
										IDMucTieuCha bigint NULL,
										SoThucTeSo decimal(18, 2) NULL,
										SoThucTeNgay date NULL,
										SoThucTeTyLe decimal(7, 2) NULL,
										IDLoaiTanSuat tinyint NULL,
										DaDuyet bit NULL,
										NgayHieuLuc date NULL,
										KyHan date NULL,
										IDHTTS bigint NULL,
										ThuTu smallint NULL,
										ThuTuCha smallint NULL,
										CapBacNhom tinyint NULL,
										SoThucTeSo2 decimal(18, 2) NULL,
										SoThucTeNgay2 date NULL,
										SoThucTeTyLe2 decimal(7, 2) NULL,
										DaDuyet2 bit NULL,
										SoThucTeSo3 decimal(18, 2) NULL,
										SoThucTeNgay3 date NULL,
										SoThucTeTyLe3 decimal(7, 2) NULL,
										DaDuyet3 bit NULL,
										CTSoThucTe nvarchar(512) NULL,
										SoThucTeSo1 decimal(18, 2) NULL,
										SoThucTeNgay1 date NULL,
										SoThucTeTyLe1 decimal(7, 2) NULL,
										DaDuyet1 bit NULL,
										bNhap bit NULL,
										bDuyet1 bit NULL,
										bDuyet2 bit NULL,
										bDuyet3 bit NULL,
										NguoiDuyet1 bigint NULL,
										NguoiDuyet2 bigint NULL,
										NguoiDuyet3 bigint NULL,
										LastUpdatedDate1 datetime NULL,
										LastUpdatedDate2 datetime NULL,
										LastUpdatedDate3 datetime NULL,
										PRIMARY KEY (IDNhomMucTieu, IDMucTieu)
										);

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
		
		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);

	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		LEFT JOIN TW_MucTieuNhapKetQua mtnkq on mtnkq.IDMucTieu=mt.IDMucTieu
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND mt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
		--AND mt.CTSoThucTe is null
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
		--AND (@DaDuyet Is null OR (@DaDuyet is not null and ISNULL(mtnkq.DaDuyet1,0) = @DaDuyet))
		AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
		AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
		AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
		--Quyền Nhập kết quả Theo cấp chỉ tiêu
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1)
				AND mt.IDQuyenNhap=1;--Quyền Nhập kết quả Theo cấp chỉ tiêu
			END
		END;
	END;

	DECLARE @TotalRow int;
	SELECT @TotalRow=COUNT(*)
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuNhapKetQua mtnkq on mtnkq.IDMucTieu=mt.IDMucTieu
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN TW_DoiTuongNhap dtcd on dtcd.IDDoiTuong=@Q_IDChucDanh and dtcd.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=2--Chức danh chỉ định
	LEFT JOIN TW_DoiTuongNhap dtns on dtns.IDDoiTuong=@IDNhanSu and dtns.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=3--Nhân sự chỉ định
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
						OR (dtcd.IDMucTieu is not null)--Chức danh chỉ định
						OR (dtns.IDMucTieu is not null)--Nhân sự chỉ định
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	--AND mt.CTSoThucTe is null
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	--AND (@DaDuyet Is null OR (@DaDuyet is not null and ISNULL(mtnkq.DaDuyet1,0) = @DaDuyet))
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'));

	INSERT INTO @TMP_MucTieuNhapKetQua (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,SoThucTeSo,SoThucTeNgay,SoThucTeTyLe,
									SoThucTeSo1,SoThucTeNgay1,SoThucTeTyLe1,DaDuyet1,
									SoThucTeSo2,SoThucTeNgay2,SoThucTeTyLe2,DaDuyet2,
									SoThucTeSo3,SoThucTeNgay3,SoThucTeTyLe3,DaDuyet3,
									bNhap,bDuyet1,bDuyet2,bDuyet3,
									TenMucTieu,MaMucTieu,IDNguoiPhuTrach,IDChucDanh,IDCoCau,SoKeHoachSo,SoKeHoachNgay,SoKeHoachTyLe,CTSoThucTe,
									IDDonViTinh,CoLopCon,CapBac,CayThuMuc,IDMucTieuCha,IDLoaiTanSuat,KyHan,IDHTTS,ThuTu,ThuTuCha,CapBacNhom,
									NguoiDuyet1,NguoiDuyet2,NguoiDuyet3,LastUpdatedDate1,LastUpdatedDate2,LastUpdatedDate3)
	SELECT mt.IDNhomMucTieu, mt.IDMucTieu,@IDKhachHang, ROW_NUMBER() OVER (ORDER BY lmt.ThuTu,nmt.ThuTuCha, nmt.ThuTu,nmt.CapBac, mt.MaThuMuc) AS STT,mtnkq.SoThucTeSo,mtnkq.SoThucTeNgay,mtnkq.SoThucTeTyLe,
									mtnkq.SoThucTeSo1,mtnkq.SoThucTeNgay1,mtnkq.SoThucTeTyLe1,ISNULL(mtnkq.IDTrangThaiDuyet1,0),
									mtnkq.SoThucTeSo2,mtnkq.SoThucTeNgay2,mtnkq.SoThucTeTyLe2,ISNULL(mtnkq.IDTrangThaiDuyet2,0),
									mtnkq.SoThucTeSo3,mtnkq.SoThucTeNgay3,mtnkq.SoThucTeTyLe3,ISNULL(mtnkq.IDTrangThaiDuyet3,0),
									(CASE 
										WHEN mt.IDQuyenNhap=0 then 1
										WHEN mt.IDQuyenNhap=1 then 1 --Theo cấp chỉ tiêu
										WHEN mt.IDQuyenDuyet=2 and dtcd.IDMucTieu is not null then 1
										WHEN mt.IDQuyenDuyet=3 and dtns.IDMucTieu is not null then 1
										ELSE 0
									END) as bNhap,
									(CASE 
										WHEN mt.IDQuyenDuyet=1 then 1 --Theo cấp chỉ tiêu
										WHEN mt.IDQuyenDuyet=2 and dtdcd1.IDMucTieu is not null then 1
										WHEN mt.IDQuyenDuyet=3 and dtdns1.IDMucTieu is not null then 1
										ELSE 0
									END) as bDuyet1,
									(CASE 
										WHEN dtdcd2.IDMucTieu is not null or dtdns2.IDMucTieu is not null then 1
										ELSE 0
									END) as bDuyet2,
									(CASE 
										WHEN dtdcd3.IDMucTieu is not null or dtdns3.IDMucTieu is not null then 1
										ELSE 0
									END) as bDuyet3,
									mt.TenMucTieu,mt.MaMucTieu,mt.IDNguoiPhuTrach,mt.IDChucDanh,mt.IDCoCau,mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,CTSoThucTe,
									mt.IDDonViTinh,ISNULL(mt.CoLopCon,0),ISNULL(mt.CapBac,0),mt.CayThuMuc,mt.IDMucTieuCha,mt.IDLoaiTanSuat, mt.KyHan,mt.IDHTTS,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac,
									mtnkq.NguoiDuyet1,mtnkq.NguoiDuyet2,mtnkq.NguoiDuyet3,mtnkq.NgayDuyet1,mtnkq.NgayDuyet2,mtnkq.NgayDuyet3
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuNhapKetQua mtnkq on mtnkq.IDMucTieu=mt.IDMucTieu
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	--Quyền Nhập
	LEFT JOIN TW_DoiTuongNhap dtcd on dtcd.IDDoiTuong=@Q_IDChucDanh and dtcd.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=2--Chức danh chỉ định NHẬP
	LEFT JOIN TW_DoiTuongNhap dtns on dtns.IDDoiTuong=@IDNhanSu and dtns.IDMucTieu=mt.IDMucTieu and mt.IDQuyenNhap=3--Nhân sự chỉ định NHẬP
	--Quyền Duyệt 1
	LEFT JOIN TW_DoiTuongDuyet dtdcd1 on dtdcd1.IDDoiTuong=@Q_IDChucDanh and dtdcd1.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=2--Chức danh chỉ định DUYỆT 1
	LEFT JOIN TW_DoiTuongDuyet dtdns1 on dtdns1.IDDoiTuong=@IDNhanSu and dtdns1.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet=3--Nhân sự chỉ định DUYỆT 1
	--Quyền Duyệt 2
	LEFT JOIN TW_DoiTuongDuyet2 dtdcd2 on dtdcd2.IDDoiTuong=@Q_IDChucDanh and dtdcd2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=2--Chức danh chỉ định DUYỆT 2
	LEFT JOIN TW_DoiTuongDuyet2 dtdns2 on dtdns2.IDDoiTuong=@IDNhanSu and dtdns2.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet2=3--Nhân sự chỉ định DUYỆT 2
	--Quyền Duyệt 3
	LEFT JOIN TW_DoiTuongDuyet3 dtdcd3 on dtdcd3.IDDoiTuong=@Q_IDChucDanh and dtdcd3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=2--Chức danh chỉ định DUYỆT 3
	LEFT JOIN TW_DoiTuongDuyet3 dtdns3 on dtdns3.IDDoiTuong=@IDNhanSu and dtdns3.IDMucTieu=mt.IDMucTieu and mt.IDQuyenDuyet3=3--Nhân sự chỉ định DUYỆT 3

	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
						OR (dtcd.IDMucTieu is not null)--Chức danh chỉ định
						OR (dtns.IDMucTieu is not null)--Nhân sự chỉ định
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Duyệt cấp 1,2,3
	--AND mt.CTSoThucTe is null
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	--AND (@DaDuyet Is null OR (@DaDuyet is not null and ISNULL(mtnkq.DaDuyet1,0) = @DaDuyet))
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY STT
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;

	INSERT INTO @TMP_MucTieuNhapKetQua (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,TenMucTieu,MaMucTieu,IDHTTS,ThuTu,ThuTuCha,CapBacNhom)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,@IDKhachHang,0 as STT,nmt.TenNhomMucTieu as TenMucTieu,nmt.MaNhomMucTieu,ISNULL(@IDHTTS,0),nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)>0 and ISNULL(nmt.SuDung,0)=1
	AND IDNhomMucTieu IN (SELECT distinct IDNhomMucTieu FROM @TMP_MucTieuNhapKetQua)

	INSERT INTO @TMP_MucTieuNhapKetQua (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,TenMucTieu,MaMucTieu,IDHTTS,ThuTu,ThuTuCha,CapBacNhom)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,@IDKhachHang,0 as STT,nmt.TenNhomMucTieu as TenMucTieu,nmt.MaNhomMucTieu,ISNULL(@IDHTTS,0),nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)=0 and ISNULL(nmt.SuDung,0)=1
	AND (
			IDNhomMucTieu in  (SELECT IDNhomMucTieu from @TMP_MucTieuNhapKetQua tmp WHERE tmp.IDMucTieu>0)
			OR
			IDNhomMucTieu in  (SELECT nmt.IDCha from @TMP_MucTieuNhapKetQua tmp 
								INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu
								WHERE tmp.IDMucTieu<0)
		)
	--Kiểm tra nhóm mục tiêu
	DECLARE @CountNhom int=0;
	SELECT @CountNhom=COUNT(*) FROM @TMP_MucTieuNhapKetQua WHERE IDMucTieu<0;
	IF(@CountNhom=0)
	BEGIN
		INSERT INTO @TMP_MucTieuNhapKetQua (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom)
		VALUES (0, 0-@TotalRow,'','',@IDKhachHang,0,0,0,0)
	END;
	SELECT tmp.*,ccpt.TenCoCau as TenCoCauPT,ccpt.TenCoCauNgan as TenCoCauNganPT,
	dvt.IDKieuDuLieu,dvt.TenDonViTinh,'' as TenKyDanhGia, lts.TenLoaiTanSuat,
	npt.HoVaTen as TenNguoiPhuTrach, cd.TenChucDanh, cc.TenCoCau, npt.AnhNhanSu,
	npt.TenNhanSuNgan,cc.TenCoCauNgan,cd.TenChucDanhNgan, htts.TenTanSuat as KyDanhGia,
	nsd1.MaNhanSu +' - '+ nsd1.HoVaTen as TenNguoiDuyet1,
	nsd2.MaNhanSu +' - '+ nsd2.HoVaTen as TenNguoiDuyet2,
	nsd3.MaNhanSu +' - '+ nsd3.HoVaTen as TenNguoiDuyet3,
	FORMAT(tmp.LastUpdatedDate1, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet1,
	FORMAT(tmp.LastUpdatedDate2, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet2,
	FORMAT(tmp.LastUpdatedDate3, 'yyyy-MM-dd hh:mm:ss') as sNgayDuyet3
	FROM @TMP_MucTieuNhapKetQua tmp
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=@IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=tmp.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=tmp.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=tmp.IDCoCau
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=tmp.IDDonViTinh
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=@IDHTMT and htts.IDHTTS=tmp.IDHTTS and htts.IDLoaiTanSuat=tmp.IDLoaiTanSuat
	--LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=tmp.IDNhomCap and nc.IDKhachHang=@IDKhachHang
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=tmp.IDLoaiTanSuat
	LEFT JOIN SYS_NhanSu nsd1 on nsd1.IDNhanSu=tmp.NguoiDuyet1
	LEFT JOIN SYS_NhanSu nsd2 on nsd2.IDNhanSu=tmp.NguoiDuyet2
	LEFT JOIN SYS_NhanSu nsd3 on nsd3.IDNhanSu=tmp.NguoiDuyet3
	ORDER BY lmt.ThuTu, tmp.ThuTuCha, tmp.ThuTu,tmp.IDNhomMucTieu,tmp.STT;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuSearch]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuSearch]
@IDHTMT	bigint = null,
@IDCha bigint=null,
@IDNhomCap tinyint =null,
@IDLoaiTanSuat tinyint=null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@IDTrangThaiDuyet tinyint=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @TMP_MucTieu TABLE( IDNhomMucTieu bigint NOT NULL,
								IDMucTieu bigint NOT NULL,
								IDKhachHang int NOT NULL,
								STT int NULL,
								TenMucTieu nvarchar(2000) NULL,
								MaMucTieu nvarchar(100) NULL,
								TrongSoPT decimal(13, 5) NULL,
								IDCoCau bigint NULL,
								IDNguoiPhuTrach bigint NULL,
								ThuTu smallint NULL,
								ThuTuCha smallint NULL,
								CapBacNhom tinyint NULL,
								PRIMARY KEY (IDNhomMucTieu, IDMucTieu)
							  );

	--@ChuThe: 0-Tổ chức, 1-Cá nhân
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (@IDCoCau IS NULL AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
	END;

	DECLARE @CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	DECLARE @TotalRow int;

	SELECT @TotalRow=COUNT(*)
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0))
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	where htmt.IDKhachHang=@IDKhachHang
	AND htmt.SuDung=1
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@IDTrangThaiDuyet Is null OR (@IDTrangThaiDuyet is not null and ISNULL(mt.IDTrangThaiDuyet,0) = @IDTrangThaiDuyet))
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'));

	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,TrongSoPT,IDKhachHang,IDCoCau,STT,ThuTu,ThuTuCha,CapBacNhom)
	SELECT mt.IDNhomMucTieu, mt.IDMucTieu,mt.MaMucTieu,mt.TenMucTieu,mtts.TrongSoPT,htmt.IDKhachHang,mt.IDCoCau,ROW_NUMBER() OVER (ORDER BY lmt.ThuTu,nmt.ThuTuCha, nmt.ThuTu,nmt.CapBac, mt.MaThuMuc) AS STT,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0))
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	where htmt.IDKhachHang=@IDKhachHang
	AND htmt.SuDung=1
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (@IDLoaiTanSuat Is null OR (@IDLoaiTanSuat is not null and mt.IDLoaiTanSuat = @IDLoaiTanSuat))
	AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@IDTrangThaiDuyet Is null OR (@IDTrangThaiDuyet is not null and ISNULL(mt.IDTrangThaiDuyet,0) = @IDTrangThaiDuyet))
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY STT
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
	
	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom)
	SELECT IDNhomMucTieu, 0-@TotalRow as IDMucTieu,nmt.MaNhomMucTieu as MaMucTieu,nmt.TenNhomMucTieu as TenMucTieu,@IDKhachHang,0,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)>0 and ISNULL(nmt.SuDung,0)=1
	AND IDNhomMucTieu IN (SELECT distinct IDNhomMucTieu FROM @TMP_MucTieu)

	INSERT INTO @TMP_MucTieu (IDNhomMucTieu,IDMucTieu,MaMucTieu,TenMucTieu,IDKhachHang,STT,ThuTu,ThuTuCha,CapBacNhom)
	SELECT IDNhomMucTieu, 0-@TotalRow as IDMucTieu,nmt.MaNhomMucTieu as MaMucTieu,nmt.TenNhomMucTieu as TenMucTieu,@IDKhachHang,0,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)=0 and ISNULL(nmt.SuDung,0)=1
	AND (
			IDNhomMucTieu in  (SELECT IDNhomMucTieu from @TMP_MucTieu tmp WHERE tmp.IDMucTieu>0)
			OR
			IDNhomMucTieu in  (SELECT nmt.IDCha from @TMP_MucTieu tmp 
								INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu
								WHERE tmp.IDMucTieu<0)
		)

	SELECT tmp.*, lts.TenLoaiTanSuat, npt.HoVaTen as TenNguoiPhuTrach, cd.TenChucDanh,cc.TenCoCau,mt.KyHan,npt.AnhNhanSu,
	ISNULL(mt.CapBac,0) as CapBac,ISNULL(mt.CoLopCon,0) as CoLopCon, htts.TenTanSuat as KyDanhGia
	FROM @TMP_MucTieu tmp
	LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_MucTieu mt on mt.IDMucTieu=tmp.IDMucTieu AND mt.IDHTMT=@IDHTMT
	LEFT JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=mt.IDHTMT and htts.IDHTTS=mt.IDHTTS and htts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	ORDER BY lmt.ThuTu, tmp.ThuTuCha, tmp.ThuTu,tmp.IDNhomMucTieu,tmp.STT;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuTask]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuTask]
@IDMucTieu	bigint,
@IDNhanSu bigint
AS
BEGIN
	SELECT * FROM TW_MucTieuTask 
	WHERE IDNhanSu=@IDNhanSu
	AND (@IDMucTieu IS NULL OR IDMucTieu=@IDMucTieu);
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuTaskLich]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuTaskLich]
@IDMucTieu	bigint,
@IDNhanSu bigint,
@DateFrom date,
@DateTo date
AS
BEGIN
	SELECT * FROM TW_MucTieuTask 
	WHERE IDNhanSu=@IDNhanSu
	AND (KyHan BETWEEN @DateFrom AND @DateTo)
	AND (@IDMucTieu IS NULL OR IDMucTieu=@IDMucTieu)
	ORDER BY KyHan,TenTask;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSMucTieuTrongSo]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[sp_LAY_DSMucTieuTrongSo]
@IDHTMT	bigint = null,
@IDNhomCap tinyint =null,
@IDHTTS bigint,
@ChuThe tinyint,
@IDCoCau bigint=null,
@IDCoCauBP bigint=null,
@DaDuyet bit=null,
@IDMucUuTien tinyint=null,
@IDNguoiPhuTrach bigint=null,
@IDLoaiMucTieu tinyint=null,
@ChamTienDo bit=null,
@CanhBaoTienDo bit=null,
@IsDelete bit=0,
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @TMP_MucTieuTrongSo TABLE( IDNhomMucTieu bigint NOT NULL,
										IDMucTieu bigint NOT NULL,
										IDCoCau bigint NOT NULL,
										IDNguoiPhuTrach bigint NOT NULL,
										IDKhachHang int NOT NULL,
										STT int NULL,
										TenMucTieu nvarchar(2000) NULL,
										MaMucTieu nvarchar(100) NULL,
										IDChucDanh bigint NULL,
										SoKeHoachSo decimal(18, 2) NULL,
										SoKeHoachNgay date NULL,
										SoKeHoachTyLe decimal(7, 2) NULL,
										IDDonViTinh bigint NULL,
										IDNhomCap tinyint NULL,
										CoLopCon bit NULL,
										CapBac tinyint NULL,
										CayThuMuc nvarchar(256) NULL,
										IDMucTieuCha bigint NULL,
										IDLoaiTanSuat tinyint NULL,
										DaDuyet bit NULL,
										KyHan date NULL,
										TrongSo decimal(5, 2) NULL,
										TrongSoPT decimal(13, 5) NULL,
										ThuTu smallint NULL,
										ThuTuCha smallint NULL,
										CapBacNhom tinyint NULL,
										PRIMARY KEY (IDNhomMucTieu, IDMucTieu, IDCoCau, IDNguoiPhuTrach)
									);

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	IF @IDCoCauBP is not null 
	BEGIN
		SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	--1: nhân sự, 2: Quản lý, 3: Bộ phận, 4: Chỉ định BP, 5: Toàn quyền
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4--Khong xem BP con
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);

	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND mt.IDHTMT=@IDHTMT
		AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
		AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
		AND (@IDCoCau Is null OR (@IDCoCau is not null and mt.IDCoCau = @IDCoCau))
		AND (ISNULL(mt.IDTrangThaiDuyet,0)=1 OR ISNULL(mt.IDTrangThaiDuyet2,0)=1 OR ISNULL(mt.IDTrangThaiDuyet3,0)=1)
		AND ISNULL(mt.IDTrangThaiDuyet2,0)!=2
		AND ISNULL(mt.IDTrangThaiDuyet3,0)!=2
		AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
		AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
		AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
		AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	DECLARE @TotalRow int;
	SELECT @TotalRow=COUNT(*)
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0))
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (ISNULL(mt.IDTrangThaiDuyet,0)=1 OR ISNULL(mt.IDTrangThaiDuyet2,0)=1 OR ISNULL(mt.IDTrangThaiDuyet3,0)=1)
	AND ISNULL(mt.IDTrangThaiDuyet2,0)!=2
	AND ISNULL(mt.IDTrangThaiDuyet3,0)!=2
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (
			(ISNULL(@ChuThe,0) = 0 AND mt.IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@DaDuyet Is null OR (@DaDuyet is not null and ISNULL(mtts.DaDuyet,0) = @DaDuyet))
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'));

	INSERT INTO @TMP_MucTieuTrongSo (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,TrongSo,TrongSoPT,
									TenMucTieu,MaMucTieu,IDNguoiPhuTrach,IDChucDanh,IDCoCau,SoKeHoachSo,SoKeHoachNgay,SoKeHoachTyLe,daDuyet,
									IDDonViTinh,CoLopCon,CapBac,CayThuMuc,IDMucTieuCha,IDLoaiTanSuat,KyHan,ThuTu,ThuTuCha,CapBacNhom)
	SELECT mt.IDNhomMucTieu, mt.IDMucTieu,@IDKhachHang, ROW_NUMBER() OVER (ORDER BY lmt.ThuTu,nmt.ThuTuCha, nmt.ThuTu,nmt.CapBac, mt.MaThuMuc) AS STT,mt.TrongSo,mtts.TrongSoPT,
									mt.TenMucTieu,mt.MaMucTieu,ISNULL(mt.IDNguoiPhuTrach,0),mt.IDChucDanh,ISNULL(mt.IDCoCau,0),mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,ISNULL(mtts.daDuyet,0),
									mt.IDDonViTinh,ISNULL(mt.CoLopCon,0),ISNULL(mt.CapBac,0),mt.CayThuMuc,mt.IDMucTieuCha,mt.IDLoaiTanSuat,mt.KyHan,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=@IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND  ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0))
			)
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND mt.IDHTMT=@IDHTMT
	AND (@IDNhomCap is null or cc.IDNhomCap=@IDNhomCap)
	AND (ISNULL(mt.IDTrangThaiDuyet,0)=1 OR ISNULL(mt.IDTrangThaiDuyet2,0)=1 OR ISNULL(mt.IDTrangThaiDuyet3,0)=1)
	AND ISNULL(mt.IDTrangThaiDuyet2,0)!=2
	AND ISNULL(mt.IDTrangThaiDuyet3,0)!=2
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(mt.IsDelete,0) = @IsDelete))
	AND (@IDHTTS Is null OR (@IDHTTS is not null and mt.IDHTTS = @IDHTTS))
	AND (
			(ISNULL(@ChuThe,0) = 0 AND mt.IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	AND (@IDCoCauBP Is null OR (@IDCoCauBP is not null and cc.CayThuMuc like @CayThuMucBP+'%'))
	AND (@DaDuyet Is null OR (@DaDuyet is not null and ISNULL(mtts.DaDuyet,0) = @DaDuyet))
	AND (@IDMucUuTien Is null OR (@IDMucUuTien is not null and mt.IDMucUuTien = @IDMucUuTien))
	AND (@IDNguoiPhuTrach Is null OR (@IDNguoiPhuTrach is not null and mt.IDNguoiPhuTrach = @IDNguoiPhuTrach))
	AND (@IDLoaiMucTieu Is null OR (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu = @IDLoaiMucTieu))
	AND (@ChamTienDo Is null OR (@ChamTienDo is not null and mt.ChamTienDo = @ChamTienDo))
	AND (@CanhBaoTienDo Is null OR (@CanhBaoTienDo is not null and mt.CanhBaoTienDo = @CanhBaoTienDo))
	AND (@Keyword is null or (@Keyword is not null and lower(mt.MaMucTieu) + ' ' + lower(mt.TenMucTieu) like '%' + lower(@Keyword) + '%'))
	ORDER BY STT
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;

	INSERT INTO @TMP_MucTieuTrongSo (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,TenMucTieu,MaMucTieu,TrongSo,IDCoCau,IDNguoiPhuTrach,ThuTu,ThuTuCha,CapBacNhom)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,@IDKhachHang,0 as STT,nmt.TenNhomMucTieu as TenMucTieu,nmt.MaNhomMucTieu,null,ISNULL(@IDCoCau,0),0,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)>0 and ISNULL(nmt.SuDung,0)=1
	AND IDNhomMucTieu IN (SELECT distinct IDNhomMucTieu FROM @TMP_MucTieuTrongSo)

	INSERT INTO @TMP_MucTieuTrongSo (IDNhomMucTieu,IDMucTieu,IDKhachHang,STT,TenMucTieu,MaMucTieu,TrongSo,IDCoCau,IDNguoiPhuTrach,ThuTu,ThuTuCha,CapBacNhom)
	SELECT nmt.IDNhomMucTieu, 0-@TotalRow as IDMucTieu,@IDKhachHang,0 as STT,nmt.TenNhomMucTieu as TenMucTieu,nmt.MaNhomMucTieu,null,ISNULL(@IDCoCau,0),0,nmt.ThuTu,nmt.ThuTuCha,nmt.CapBac
	FROM TW_NhomMucTieu nmt
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	WHERE nmt.IDHTMT=@IDHTMT and ISNULL(nmt.IsDelete,0)=0 and ISNULL(nmt.IDCha,0)=0 and ISNULL(nmt.SuDung,0)=1
	AND (
			IDNhomMucTieu in  (SELECT IDNhomMucTieu from @TMP_MucTieuTrongSo tmp WHERE tmp.IDMucTieu>0)
			OR
			IDNhomMucTieu in  (SELECT nmt.IDCha from @TMP_MucTieuTrongSo tmp 
								INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu
								WHERE tmp.IDMucTieu<0)
		)
	
	SELECT tmp.*,ccpt.TenCoCau as TenCoCauPT,ccpt.TenCoCauNgan as TenCoCauNganPT,
	dvt.IDKieuDuLieu,dvt.TenDonViTinh,nc.TenNhomCap,'' as TenKyDanhGia, lts.TenLoaiTanSuat,
	npt.HoVaTen as TenNguoiPhuTrach, cd.TenChucDanh, cc.TenCoCau, npt.AnhNhanSu,
	npt.TenNhanSuNgan,cc.TenCoCauNgan,cd.TenChucDanhNgan, htts.TenTanSuat as KyDanhGia
	FROM @TMP_MucTieuTrongSo tmp
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=tmp.IDNhomMucTieu and nmt.IDHTMT=@IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=@IDHTMT
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=@IDHTMT and htts.IDHTTS=@IDHTTS and htts.IDLoaiTanSuat=tmp.IDLoaiTanSuat
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=tmp.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=tmp.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=tmp.IDCoCau
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=tmp.IDDonViTinh
	LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=tmp.IDNhomCap and nc.IDKhachHang=@IDKhachHang
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=tmp.IDLoaiTanSuat
	ORDER BY lmt.ThuTu, tmp.ThuTuCha, tmp.ThuTu,tmp.IDNhomMucTieu,tmp.STT;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSNhanSu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSNhanSu]
@IDNhomCap tinyint=null,
@IDCha bigint=null,
@TrangThai tinyint=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_ChucDanh WHERE IDChucDanh=@Q_IDChucDanh;
		INSERT INTO @TableID (id)
		SELECT IDChucDanh from SYS_ChucDanh where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
	END;

	IF @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	DECLARE @TotalRow int;

	SELECT @TotalRow=COUNT(*)
	FROM SYS_NhanSu ns
	LEFT JOIN SYS_CoCau cc on ns.IDCoCau = cc.IDCoCau and ns.IDKhachHang=cc.IDKhachHang
	LEFT JOIN SYS_ChucDanh cd on ns.IDChucDanh=cd.IDChucDanh and ns.IDCoCau=cc.IDCoCau
	WHERE ns.IDKhachHang=@IDKhachHang
	AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND ns.IDNhanSu in (select id from @TableID))
						OR (@IDQuyen=2 AND cd.IDChucDanh in (select id from @TableID))
						OR (@IDQuyen in (3,4) AND (cc.IDCoCau in (select id from @TableID)))
					)
				)
		)
	AND (@IDCha is null or (@IDCha is not null and ns.IDCoCau=@IDCha))
	AND (@TrangThai is null or (@TrangThai is not null and ns.TrangThai=@TrangThai))
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(cd.IsDelete,0) = @IsDelete and ISNULL(ns.IsDelete,0) = @IsDelete))
	AND (@IDNhomCap is null or (@IDNhomCap is not null and cc.IDNhomCap=@IDNhomCap))
	AND (@Keyword is null or (@Keyword is not null and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) like '%' + lower(@Keyword) + '%'));
	
	SELECT ns.*, cc.CapBac AS CapBacCoCau,cc.MaCoCau, cd.MaChucDanh, cd.TenChucDanh, cc.TenCoCau,@TotalRow as TotalRow
	FROM SYS_NhanSu ns
	LEFT JOIN SYS_CoCau cc on ns.IDCoCau = cc.IDCoCau and ns.IDKhachHang=cc.IDKhachHang
	LEFT JOIN SYS_ChucDanh cd on ns.IDChucDanh=cd.IDChucDanh and ns.IDCoCau=cc.IDCoCau
	WHERE ns.IDKhachHang=@IDKhachHang
	AND (@IDQuyen=5 
			OR (@IDQuyen!=5 AND 
					(
						(@IDQuyen=1 AND ns.IDNhanSu in (select id from @TableID))
						OR (@IDQuyen=2 AND cd.IDChucDanh in (select id from @TableID))
						OR (@IDQuyen in (3,4) AND (cc.IDCoCau in (select id from @TableID)))
					)
				)
		)
	AND (@IDCha is null or (@IDCha is not null and ns.IDCoCau=@IDCha))
	AND (@TrangThai is null or (@TrangThai is not null and ns.TrangThai=@TrangThai))
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(cd.IsDelete,0) = @IsDelete and ISNULL(ns.IsDelete,0) = @IsDelete))
	AND (@IDNhomCap is null or (@IDNhomCap is not null and cc.IDNhomCap=@IDNhomCap))
	AND (@Keyword is null or (@Keyword is not null and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) like '%' + lower(@Keyword) + '%'))
	ORDER BY ns.MaNhanSu, cc.IDNhomCap
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSNhanSuEmail]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSNhanSuEmail]
@IDKhachHang int
AS
BEGIN
	DECLARE @Date datetime;
	SELECT @Date=MAX(cb.CreatedDate) 
	FROM TW_CanhBao cb
	INNER JOIN SYS_NhanSu ns on ns.IDNhanSu=cb.IDNguoiPhuTrach 
	WHERE ns.IDKhachHang=@IDKhachHang
	AND ISNULL(ns.IsDelete,0)=0
	AND ns.Email is not null
	AND ns.Email like '%@%'
	AND ns.Email like '%.%';

	SELECT ns.IDKhachHang,ns.IDNhanSu,ns.Email
	FROM SYS_NhanSu ns
	WHERE ns.IDKhachHang=@IDKhachHang
	AND ISNULL(ns.IsDelete,0)=0
	AND ns.Email is not null
	AND ns.Email like '%@%'
	AND ns.Email like '%.%'
	--AND ns.IDNhanSu in (SELECT IDNguoiPhuTrach
	--					FROM TW_CanhBao
	--					WHERE IDKhachHang=@IDKhachHang
	--					  AND CreatedDate=@Date)
	order BY ns.IDNhanSu
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSNhomCap]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSNhomCap]
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	With Count_CTE 
	AS 
	(
		SELECT COUNT(*) AS TotalRow FROM TW_NhomCap
		WHERE IDKhachHang=@IDKhachHang
		AND (@SuDung is null or (@SuDung is not null and SuDung=@SuDung))
		AND ISNULL(IsDelete,0)=0
	)
	SELECT nc.*,Count_CTE.TotalRow
	FROM TW_NhomCap nc
	CROSS JOIN Count_CTE
	WHERE IDKhachHang=@IDKhachHang
	AND (@SuDung is null or (@SuDung is not null and nc.SuDung=@SuDung))
	AND ISNULL(IsDelete,0)=0
	ORDER BY nc.ThuTu,nc.MaNhomCap
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSNhomMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSNhomMucTieu]
@IDHTMT bigint=null,
@IDLoaiMucTieu tinyint=null,
@IDCoCau bigint=null,
@SuDung bit=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int,
@IsDelete bit=0
AS
BEGIN
	With Count_CTE 
	AS 
	(
		SELECT COUNT(*) AS TotalRow FROM 
		TW_NhomMucTieu nmt
		INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=nmt.IDHTMT
		WHERE nmt.IDHTMT=@IDHTMT
		AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(nmt.IsDelete,0) = @IsDelete))
		AND (@IDLoaiMucTieu is null or (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu=@IDLoaiMucTieu))
		AND (@IDCoCau is null or (@IDCoCau is not null and nmt.IDCoCau=@IDCoCau) or nmt.IDCoCau is null)
		AND (@SuDung is null or (@SuDung is not null and nmt.SuDung=@SuDung))
	)
	SELECT nmt.*,Count_CTE.TotalRow,lmt.TenLoaiMucTieu,cc.MaCoCau,cc.TenCoCau
	FROM TW_NhomMucTieu nmt
	CROSS JOIN Count_CTE
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu and lmt.IDHTMT=nmt.IDHTMT
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=nmt.IDHTMT and htmt.IDKhachHang=@IDKhachHang
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=nmt.IDCoCau and cc.IDKhachHang=@IDKhachHang
	WHERE nmt.IDHTMT=@IDHTMT
	AND (@IsDelete Is null OR (@IsDelete is not null and ISNULL(nmt.IsDelete,0) = @IsDelete))
	AND (@IDLoaiMucTieu is null or (@IDLoaiMucTieu is not null and nmt.IDLoaiMucTieu=@IDLoaiMucTieu))
	AND (@IDCoCau is null or (@IDCoCau is not null and nmt.IDCoCau=@IDCoCau) or nmt.IDCoCau is null)
	AND (@SuDung is null or (@SuDung is not null and nmt.SuDung=@SuDung))
	ORDER BY lmt.ThuTu,lmt.TenLoaiMucTieu, nmt.ThuTuCha, nmt.IDCha, nmt.ThuTu, nmt.MaNhomMucTieu
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END

GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSQuyCheDanhGia]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_LAY_DSQuyCheDanhGia]
@DateFrom date,
@DateTo date,
@IDTrangThai tinyint,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @TotalRow int;
	DECLARE @Date date=CAST(GETDATE() AS Date);
	--IDTrangThai = null: tất cả, 1:Còn hiệu lực, 0: Hết hiệu lực
	SELECT @TotalRow=COUNT(*)
	FROM TW_QuyCheDanhGia qc
	WHERE ((@IDTrangThai is null)
			OR 
			(@IDTrangThai=1
				AND (qc.NgayHieuLuc is null or (qc.NgayHieuLuc is not null and qc.NgayHieuLuc<=@Date))
				AND (qc.NgayHetHieuLuc is null or (qc.NgayHetHieuLuc is not null and qc.NgayHetHieuLuc>=@Date))
			)
			OR (@IDTrangThai=0 AND (qc.NgayHieuLuc is not null and qc.NgayHieuLuc>@Date))
			OR (@IDTrangThai=0 AND (qc.NgayHetHieuLuc is not null and qc.NgayHetHieuLuc<@Date))
		  )
	AND ((@DateFrom is null)
	     OR
		 (@DateFrom is not null AND (qc.NgayHieuLuc is null or (qc.NgayHieuLuc is not null and qc.NgayHieuLuc<=@Date)))
		)
	AND ((@DateTo is null)
	     OR
		 (@DateTo is not null AND (qc.NgayHetHieuLuc is null or (qc.NgayHetHieuLuc is not null and qc.NgayHetHieuLuc>=@Date)))
		)

	SELECT qc.*,mBP.MaMucDanhGia as MaMucBoPhan, tmp.MaMucCaNhan
	FROM TW_QuyCheDanhGia qc
	INNER JOIN TW_MucDanhGia mBP on mBP.IDMucDanhGia=qc.IDMucBoPhan
	LEFT JOIN (SELECT qct.IDQuyChe, STRING_AGG (CONVERT(NVARCHAR(4000),mCN.MaMucDanhGia), ';') AS MaMucCaNhan
				FROM TW_QuyCheDanhGiaChiTiet qct
				INNER JOIN TW_MucDanhGia mCN on mCN.IDMucDanhGia=qct.IDMucCaNhan
				GROUP BY qct.IDQuyChe) tmp ON tmp.IDQuyChe=qc.IDQuyChe
	WHERE ((@IDTrangThai is null)
			OR 
			(@IDTrangThai=1
				AND (qc.NgayHieuLuc is null or (qc.NgayHieuLuc is not null and qc.NgayHieuLuc<=@Date))
				AND (qc.NgayHetHieuLuc is null or (qc.NgayHetHieuLuc is not null and qc.NgayHetHieuLuc>=@Date))
			)
			OR (@IDTrangThai=0 AND (qc.NgayHieuLuc is not null and qc.NgayHieuLuc>@Date))
			OR (@IDTrangThai=0 AND (qc.NgayHetHieuLuc is not null and qc.NgayHetHieuLuc<@Date))
		  )
	AND ((@DateFrom is null)
	     OR
		 (@DateFrom is not null AND (qc.NgayHieuLuc is null or (qc.NgayHieuLuc is not null and qc.NgayHieuLuc<=@Date)))
		)
	AND ((@DateTo is null)
	     OR
		 (@DateTo is not null AND (qc.NgayHetHieuLuc is null or (qc.NgayHetHieuLuc is not null and qc.NgayHetHieuLuc>=@Date)))
		)
	ORDER BY qc.MaQuyChe, mBP.DiemDen desc
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSTyTrongChucDanh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSTyTrongChucDanh]
@IDHTMT bigint=null,
@IDHTTS bigint=null,
@IDNguoiPhuTrach bigint=null,
@IDChucDanh bigint=null,
@PageSize int = 20, 
@PageIndex  int = 1,
@Keyword nvarchar(256),
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @Count int=0;
	
	--Kiểm tra chức danh chính
	SELECT @Count=Count(*)
	FROM SYS_NhanSu ns
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=@IDHTMT
	LEFT JOIN TW_TyTrongChucDanh ttcd on ttcd.IDHTMT=@IDHTMT AND ttcd.IDHTTS=htts.IDHTTS and ttcd.IDNhanSu=ns.IDNhanSu and ttcd.IDChucDanh=ns.IDChucDanh
	INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu and ISNULL(kn.IsDeleted,0)=0
	WHERE ns.IDKhachHang=@IDKhachHang AND ns.TrangThai=1 AND ISNULL(ns.IsDelete,0)=0 AND ns.IDChucDanh is not null
	AND htts.IDHTTS is not null
	AND (@IDHTTS IS NULL OR (@IDHTTS IS NOT NULL and htts.IDHTTS=@IDHTTS))
	AND (
			(kn.NgayHieuLuc is null or kn.NgayHieuLuc between htts.BatDau and htts.KetThuc)
			OR
			(kn.NgayHetHan is null or kn.NgayHetHan between htts.BatDau and htts.KetThuc)
		)
	AND ttcd.IDNhanSu is null;

	IF @Count>0
	BEGIN
		INSERT INTO TW_TyTrongChucDanh (IDHTMT,IDHTTS,IDNhanSu,IDChucDanh,IsKiemNhiem)
		SELECT distinct @IDHTMT,htts.IDHTTS,ns.IDNhanSu,ns.IDChucDanh,0--Chính
		FROM SYS_NhanSu ns
		LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=@IDHTMT
		LEFT JOIN TW_TyTrongChucDanh ttcd on ttcd.IDHTMT=@IDHTMT AND ttcd.IDHTTS=htts.IDHTTS and ttcd.IDNhanSu=ns.IDNhanSu and ttcd.IDChucDanh=ns.IDChucDanh
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu and ISNULL(kn.IsDeleted,0)=0
		WHERE ns.IDKhachHang=@IDKhachHang AND ns.TrangThai=1 AND ISNULL(ns.IsDelete,0)=0 AND ns.IDChucDanh is not null
		AND htts.IDHTTS is not null
		AND (@IDHTTS IS NULL OR (@IDHTTS IS NOT NULL and htts.IDHTTS=@IDHTTS))
		AND (
			(kn.NgayHieuLuc is null or kn.NgayHieuLuc between htts.BatDau and htts.KetThuc)
			OR
			(kn.NgayHetHan is null or kn.NgayHetHan between htts.BatDau and htts.KetThuc)
		)
	AND ttcd.IDNhanSu is null;
	END;

	--Kiểm tra chức danh kiêm nhiệm
	SELECT @Count=Count(*)
	FROM SYS_KiemNhiem kn
	INNER JOIN SYS_NhanSu ns on ns.DB_IDNhanSu=kn.DB_IDNhanSu
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=@IDHTMT
	INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
	LEFT JOIN TW_TyTrongChucDanh ttcd on ttcd.IDHTMT=@IDHTMT AND ttcd.IDHTTS=htts.IDHTTS and ttcd.IDNhanSu=ns.IDNhanSu and ttcd.IDChucDanh=cd.IDChucDanh
	WHERE ns.IDKhachHang=@IDKhachHang AND ns.TrangThai=1 AND ISNULL(ns.IsDelete,0)=0 AND ns.IDChucDanh is not null
	AND htts.IDHTTS is not null
	AND (@IDHTTS IS NULL OR (@IDHTTS IS NOT NULL and htts.IDHTTS=@IDHTTS))
	and ttcd.IDNhanSu is null
	AND (
			(kn.NgayHieuLuc is null or kn.NgayHieuLuc between htts.BatDau and htts.KetThuc)
			OR
			(kn.NgayHetHan is null or kn.NgayHetHan between htts.BatDau and htts.KetThuc)
		)
	AND ISNULL(kn.IsDeleted,0)=0;

	IF @Count>0
	BEGIN
		INSERT INTO TW_TyTrongChucDanh (IDHTMT,IDHTTS,IDNhanSu,IDChucDanh,IsKiemNhiem)
		SELECT distinct @IDHTMT,htts.IDHTTS,ns.IDNhanSu,cd.IDChucDanh,1--Kiêm nhiệm
		FROM SYS_KiemNhiem kn
		INNER JOIN SYS_NhanSu ns on ns.DB_IDNhanSu=kn.DB_IDNhanSu
		LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=@IDHTMT
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		LEFT JOIN TW_TyTrongChucDanh ttcd on ttcd.IDHTMT=@IDHTMT AND ttcd.IDHTTS=htts.IDHTTS and ttcd.IDNhanSu=ns.IDNhanSu and ttcd.IDChucDanh=cd.IDChucDanh
		WHERE ns.IDKhachHang=@IDKhachHang AND ns.TrangThai=1 AND ISNULL(ns.IsDelete,0)=0 AND ns.IDChucDanh is not null
		AND htts.IDHTTS is not null
		AND (@IDHTTS IS NULL OR (@IDHTTS IS NOT NULL and htts.IDHTTS=@IDHTTS))
		and ttcd.IDNhanSu is null
		AND (
			(kn.NgayHieuLuc is null or kn.NgayHieuLuc between htts.BatDau and htts.KetThuc)
			OR
			(kn.NgayHetHan is null or kn.NgayHetHan between htts.BatDau and htts.KetThuc)
		)
	AND ISNULL(kn.IsDeleted,0)=0;
	END;

	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@Q_IDChucDanh);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	DECLARE @TotalRow int;
	
	SELECT @TotalRow=COUNT(*)
	FROM TW_TyTrongChucDanh ttcd
	INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=ttcd.IDNhanSu
	INNER JOIN SYS_CoCau cc ON cc.IDCoCau=ns.IDCoCau
	INNER JOIN SYS_ChucDanh cdc ON cdc.IDChucDanh=ttcd.IDChucDanh
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTMT=@IDHTMT AND htts.IDHTTS=ttcd.IDHTTS
	WHERE ns.IDKhachHang=@IDKhachHang
	AND (@IDHTMT IS NULL OR (@IDHTMT IS NOT NULL AND ttcd.IDHTMT=@IDHTMT))
	AND (@IDHTTS IS NULL OR (@IDHTTS IS NOT NULL AND ttcd.IDHTTS=@IDHTTS))
	AND (@IDNguoiPhuTrach IS NULL OR (@IDNguoiPhuTrach IS NOT NULL AND ttcd.IDNhanSu=@IDNguoiPhuTrach))
	AND (@IDChucDanh IS NULL OR (@IDChucDanh IS NOT NULL AND ttcd.IDChucDanh=@IDChucDanh))
	AND (@Keyword is null or (@Keyword is not null  and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) + ' ' + lower(cdc.MaChucDanh) + ' ' + lower(cdc.TenChucDanh) like '%' + lower(@Keyword) + '%'))
	--ORDER BY ttcd.IsKiemNhiem;

	--SELECT @TotalRow=@IDHTTS;

	SELECT ttcd.*,htts.TenTanSuat,cc.MaCoCau,cc.TenCoCau,ns.MaNhanSu,ns.HoVaTen,ns.AnhNhanSu,cdc.MaChucDanh,cdc.TenChucDanh, @TotalRow as TotalRow
	FROM TW_TyTrongChucDanh ttcd
	INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=ttcd.IDNhanSu
	INNER JOIN SYS_CoCau cc ON cc.IDCoCau=ns.IDCoCau
	INNER JOIN SYS_ChucDanh cdc ON cdc.IDChucDanh=ttcd.IDChucDanh
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTMT=@IDHTMT AND htts.IDHTTS=ttcd.IDHTTS
	WHERE ns.IDKhachHang=@IDKhachHang
	AND (@IDHTMT IS NULL OR (@IDHTMT IS NOT NULL AND ttcd.IDHTMT=@IDHTMT))
	AND (@IDHTTS IS NULL OR (@IDHTTS IS NOT NULL AND ttcd.IDHTTS=@IDHTTS))
	AND (@IDNguoiPhuTrach IS NULL OR (@IDNguoiPhuTrach IS NOT NULL AND ttcd.IDNhanSu=@IDNguoiPhuTrach))
	AND (@IDChucDanh IS NULL OR (@IDChucDanh IS NOT NULL AND ttcd.IDChucDanh=@IDChucDanh))
	AND (@Keyword is null or (@Keyword is not null  and lower(ns.MaNhanSu) + ' ' + lower(ns.HoVaTen) + ' ' + lower(cdc.MaChucDanh) + ' ' + lower(cdc.TenChucDanh) like '%' + lower(@Keyword) + '%'))
	ORDER BY htts.BatDau, htts.TenTanSuat,cc.MaThuMuc,ns.MaNhanSu,ttcd.IsKiemNhiem
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_DSYeuToTinh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_DSYeuToTinh]
@IDMucTieu bigint
AS
BEGIN
	SELECT ytt.*,htmt.MaHTMT,mt.MaMucTieu+' - ' +mt.TenMucTieu as TenMucTieuTinh, cc.MaCoCau, cc.TenCoCau,htts.TenTanSuat
	FROM TW_YeuToTinhSoThucTe ytt
	INNER JOIN TW_MucTieu mt on mt.IDMucTieu=ytt.IDMucTieuTinh
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_HeThongTanSuat htts on htts.IDHTTS=mt.IDHTTS
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	WHERE ytt.IDMucTieu=@IDMucTieu and ytt.IDMucTieu>0
	ORDER BY ytt.ThuTu;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_KhachHang]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_LAY_KhachHang]
@ID int,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	SELECT *
	FROM SYS_KhachHang
	WHERE IDKhachHang=@ID;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_MucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_MucTieu]
@IDMucTieu bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT mt.*, tmpTV.dsThanhVien, tmpNhap.dsQuyenNhap, tmpDuyet.dsQuyenDuyet,tmpDuyet2.dsQuyenDuyet2,tmpDuyet3.dsQuyenDuyet3,
	dvt.IDKieuDuLieu, npt.HoVaTen as TenNguoiPhuTrach,mtc.MaMucTieu as MaMucTieuCha,mtc.TenMucTieu as TenMucTieuCha,mt.IDChucDanh as IDChucDanhPT
	FROM TW_MucTieu mt
	INNER JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
	LEFT JOIN TW_MucTieu mtc on mtc.IDMucTieu=ISNULL(mt.IDMucTieuCha,0)
	LEFT JOIN (SELECT tv.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),tv.IDNhanSu), ',') AS dsThanhVien FROM TW_ThanhVien tv GROUP BY tv.IDMucTieu) tmpTV on tmpTV.IDMucTieu=mt.IDMucTieu
	LEFT JOIN (SELECT dtn.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),dtn.IDDoiTuong), ',') AS dsQuyenNhap FROM TW_DoiTuongNhap dtn GROUP BY dtn.IDMucTieu) tmpNhap on tmpNhap.IDMucTieu=mt.IDMucTieu
	LEFT JOIN (SELECT dtd.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),dtd.IDDoiTuong), ',') AS dsQuyenDuyet FROM TW_DoiTuongDuyet dtd GROUP BY dtd.IDMucTieu) tmpDuyet on tmpDuyet.IDMucTieu=mt.IDMucTieu
	LEFT JOIN (SELECT dtd2.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),dtd2.IDDoiTuong), ',') AS dsQuyenDuyet2 FROM TW_DoiTuongDuyet2 dtd2 GROUP BY dtd2.IDMucTieu) tmpDuyet2 on tmpDuyet2.IDMucTieu=mt.IDMucTieu
	LEFT JOIN (SELECT dtd3.IDMucTieu, STRING_AGG (CONVERT(NVARCHAR(4000),dtd3.IDDoiTuong), ',') AS dsQuyenDuyet3 FROM TW_DoiTuongDuyet3 dtd3 GROUP BY dtd3.IDMucTieu) tmpDuyet3 on tmpDuyet3.IDMucTieu=mt.IDMucTieu
	WHERE mt.IDMucTieu=@IDMucTieu;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_MucTieuGoc]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_MucTieuGoc]
@IDMucTieu bigint = null,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDCoCauCaNhan bigint;
	DECLARE @TenCoCauCaNhan nvarchar(256);
	SELECT @IDCoCauCaNhan= MIN(IDCoCau) FROM SYS_CoCau WHERE IDNhomCap=5;
	SELECT @TenCoCauCaNhan= Macocau + ' - ' + TenCoCau FROM SYS_CoCau WHERE IDCoCau=@IDCoCauCaNhan;

	SELECT mt.*, mt.SoKeHoachSo,mt.SoKeHoachNgay,mt.SoKeHoachTyLe,dvt.IDKieuDuLieu,dvt.TenDonViTinh,mt.TrongSo,ccpt.MaCoCau as MaCoCauPT,ccpt.TenCoCau as TenCoCauPT,ccpt.TenCoCauNgan as TenCoCauNganPT,
	ttmt.TenTrangThaiMucTieu, lts.TenLoaiTanSuat, npt.MaNhanSu, npt.HoVaTen as TenNguoiPhuTrach, npt.TenNhanSuNgan, cd.MaChucDanh, cd.TenChucDanh,cd.TenChucDanhNgan, cc.MaCoCau,cc.TenCoCau,cc.TenCoCauNgan, mt.KyHan,
	--ISNULL(nkq.SoThucTeSo) as SoThucTeSo,ISNULL(nkq.SoThucTeNgay) as SoThucTeNgay,ISNULL(nkq.SoThucTeTyLe) as SoThucTeTyLe,
	ISNULL(nkq.SoThucTeSo3,ISNULL(nkq.SoThucTeSo2,ISNULL(nkq.SoThucTeSo1,nkq.SoThucTeSo))) as SoThucTeSo,
	ISNULL(nkq.SoThucTeNgay3,ISNULL(nkq.SoThucTeNgay2,ISNULL(nkq.SoThucTeNgay1,nkq.SoThucTeNgay))) as SoThucTeNgay,
	ISNULL(nkq.SoThucTeTyLe3,ISNULL(nkq.SoThucTeTyLe2,ISNULL(nkq.SoThucTeTyLe1,nkq.SoThucTeTyLe))) as SoThucTeTyLe,
	mt.NgayHoanThanh,round(ISNULL(mt.TyLeHoanThanh,mt.TyLeTamTinh),1) as TyLeHoanThanh,round(mt.DiemHoanThanh,2) as DiemHoanThanh,npt.AnhNhanSu,
	ISNULL(mt.CapBac,0) as CapBac,ISNULL(mt.CoLopCon,0) as CoLopCon, htts.TenTanSuat as KyDanhGia,
	@IDCoCauCaNhan as IDCoCauCaNhan, @TenCoCauCaNhan as TenCoCauCaNhan
	FROM TW_MucTieu mt
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu and nmt.IDHTMT=mt.IDHTMT
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDLoaiMucTieu = nmt.IDLoaiMucTieu and lmt.IDHTMT=mt.IDHTMT
	LEFT JOIN TW_MucTieuNhapKetQua nkq on nkq.IDMucTieu=mt.IDMucTieu
	LEFT JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
	LEFT JOIN SYS_CoCau ccpt on ccpt.IDCoCau=cd.IDCoCau
	LEFT JOIN TW_DonViTinh dvt on dvt.IDDonViTinh=mt.IDDonViTinh
	LEFT JOIN TW_HeThongTanSuat htts on htts.IDHTMT=mt.IDHTMT and htts.IDHTTS=mt.IDHTTS and htts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	LEFT JOIN TW_NhomCap nc on nc.IDNhomCap=cc.IDNhomCap and nc.IDKhachHang=@IDKhachHang
	LEFT JOIN ENUM_TrangThaiMucTieu ttmt on ttmt.IDTrangThaiMucTieu=mt.IDTrangThaiMucTieu
	LEFT JOIN ENUM_LoaiTanSuat lts on lts.IDLoaiTanSuat=mt.IDLoaiTanSuat
	WHERE mt.IDMucTieu=@IDMucTieu
	and htmt.IDKhachHang=@IDKhachHang;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_MucTieuQuyenDuyet]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_LAY_MucTieuQuyenDuyet]
@IDHTMT	bigint,
@IDMucTieu bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyenDuyet tinyint, @Count int = 0;
	DECLARE @QuyenDuyet int = 0;
	DECLARE @CayThuMuc nvarchar(256);

	SELECT @IDQuyenDuyet=IDQuyenDuyet,@CayThuMuc=CayThuMuc FROM TW_MucTieu WHERE IDMucTieu=@IDMucTieu and IDHTMT=@IDHTMT;
	
	--DUYỆT 1 Theo cấp chỉ tiêu
	IF ISNULL(@IDQuyenDuyet,1)=1
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_MucTieu mt
		WHERE mt.IDNguoiPhuTrach=@IDNhanSu
		AND ISNULL(mt.IsDelete,0)=0
		AND @CayThuMuc like  '%' + mt.CayThuMuc + '%';
		
		IF @Count>0 SET @QuyenDuyet=1;
	END;
	--DUYỆT 2 Chỉ định chức danh
	IF @IDQuyenDuyet=2
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_DoiTuongDuyet dtd
		INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=@IDNhanSu and ns.IDChucDanh=dtd.IDDoiTuong
		WHERE dtd.IDMucTieu=@IDMucTieu;
		IF @Count>0 SET @QuyenDuyet=1;
	END;
	--DUYỆT 3 Chỉ định nhân sự
	IF @IDQuyenDuyet=3
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_DoiTuongDuyet dtd
		INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=dtd.IDDoiTuong
		WHERE dtd.IDMucTieu=@IDMucTieu;
		IF @Count>0 SET @QuyenDuyet=1;
	END;
	SET @QuyenDuyet=1;
	SELECT 0 as QuyenNhap, @QuyenDuyet as QuyenDuyet;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_MucTieuQuyenNhap]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_LAY_MucTieuQuyenNhap]
@IDHTMT	bigint,
@IDMucTieu bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyenNhap tinyint, @Count int = 0;
	DECLARE @QuyenNhap int = 00;
	DECLARE @CayThuMuc nvarchar(256);

	SELECT @IDQuyenNhap=IDQuyenNhap,@CayThuMuc=CayThuMuc FROM TW_MucTieu WHERE IDMucTieu=@IDMucTieu and IDHTMT=@IDHTMT;
	--NHẬP 1 Theo cấp chỉ tiêu	--2 Chỉ định chức danh	--3 Chỉ định nhân sự
	IF ISNULL(@IDQuyenNhap,1)=1
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_MucTieu mt
		WHERE mt.IDNguoiPhuTrach=@IDNhanSu
		AND ISNULL(mt.IsDelete,0)=0
		AND @CayThuMuc like  '%' + mt.CayThuMuc + '%';
		
		IF @Count>0 SET @QuyenNhap=1;
	END;
	--NHẬP 2 Chỉ định chức danh
	IF @IDQuyenNhap=2
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_DoiTuongNhap dtn
		INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=@IDNhanSu and ns.IDChucDanh=dtn.IDDoiTuong
		WHERE dtn.IDMucTieu=@IDMucTieu;
		IF @Count>0 SET @QuyenNhap=1;
	END;
	--NHẬP 3 Chỉ định nhân sự
	IF @IDQuyenNhap=3
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_DoiTuongNhap dtn
		INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=dtn.IDDoiTuong
		WHERE dtn.IDMucTieu=@IDMucTieu;
		IF @Count>0 SET @QuyenNhap=1;
	END;
	SET @QuyenNhap=1;
	SELECT @QuyenNhap as QuyenNhap, 0 as QuyenDuyet;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_MucTieuQuyenNhapDuyet]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_LAY_MucTieuQuyenNhapDuyet]
@IDHTMT	bigint,
@IDMucTieu bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @IDQuyenNhap tinyint, @IDQuyenDuyet tinyint, @Count int = 0;
	DECLARE @QuyenNhap int = 0, @QuyenDuyet int = 0;
	DECLARE @CayThuMuc nvarchar(256);

	SELECT @IDQuyenNhap=IDQuyenNhap,@IDQuyenDuyet=IDQuyenDuyet,@CayThuMuc=CayThuMuc FROM TW_MucTieu WHERE IDMucTieu=@IDMucTieu and IDHTMT=@IDHTMT;
	--NHẬP 1 Theo cấp chỉ tiêu	--2 Chỉ định chức danh	--3 Chỉ định nhân sự
	IF ISNULL(@IDQuyenNhap,1)=1
	BEGIN
		
		SELECT @Count=COUNT(*) 
		FROM TW_MucTieu mt
		WHERE mt.IDNguoiPhuTrach=@IDNhanSu
		AND ISNULL(mt.IsDelete,0)=0
		AND @CayThuMuc like  '%' + mt.CayThuMuc + '%';
		
		IF @Count>0 SET @QuyenNhap=1;
	END;
	--NHẬP 2 Chỉ định chức danh
	IF @IDQuyenNhap=2
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_DoiTuongNhap dtn
		INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=@IDNhanSu and ns.IDChucDanh=dtn.IDDoiTuong
		WHERE dtn.IDMucTieu=@IDMucTieu;
		IF @Count>0 SET @QuyenNhap=1;
	END;
	--NHẬP 3 Chỉ định nhân sự
	IF @IDQuyenNhap=3
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_DoiTuongNhap dtn
		INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=dtn.IDDoiTuong
		WHERE dtn.IDMucTieu=@IDMucTieu;
		IF @Count>0 SET @QuyenNhap=1;
	END;
	--DUYỆT 1 Theo cấp chỉ tiêu
	IF ISNULL(@IDQuyenDuyet,1)=1
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_MucTieu mt
		WHERE mt.IDNguoiPhuTrach=@IDNhanSu
		AND ISNULL(mt.IsDelete,0)=0
		AND @CayThuMuc like  '%' + mt.CayThuMuc + '%';
		
		IF @Count>0 SET @QuyenDuyet=1;
	END;
	--DUYỆT 2 Chỉ định chức danh
	IF @IDQuyenDuyet=2
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_DoiTuongDuyet dtd
		INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=@IDNhanSu and ns.IDChucDanh=dtd.IDDoiTuong
		WHERE dtd.IDMucTieu=@IDMucTieu;
		IF @Count>0 SET @QuyenDuyet=1;
	END;
	--DUYỆT 3 Chỉ định nhân sự
	IF @IDQuyenDuyet=3
	BEGIN
		SELECT @Count=COUNT(*) 
		FROM TW_DoiTuongDuyet dtd
		INNER JOIN SYS_NhanSu ns ON ns.IDNhanSu=dtd.IDDoiTuong
		WHERE dtd.IDMucTieu=@IDMucTieu;
		IF @Count>0 SET @QuyenDuyet=1;
	END;
	SET @QuyenNhap=1;
	SET @QuyenDuyet=1;
	SELECT @QuyenNhap as QuyenNhap, @QuyenDuyet as QuyenDuyet;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_QuyCheDanhGia]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LAY_QuyCheDanhGia]
@IDQuyChe bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	
	SELECT qc.*--, tmpTV.dsThanhVien
	FROM TW_QuyCheDanhGia qc
	INNER JOIN TW_MucDanhGia mBP on mBP.IDMucDanhGia=qc.IDMucBoPhan
	LEFT JOIN (SELECT qct.IDQuyChe, STRING_AGG (CONVERT(NVARCHAR(4000),qct.IDMucCaNhan), ';') AS MaMucCaNhan
				FROM TW_QuyCheDanhGiaChiTiet qct
				GROUP BY qct.IDQuyChe) tmp ON tmp.IDQuyChe=qc.IDQuyChe
	WHERE qc.IDQuyChe=@IDQuyChe;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_TrangThaiDuyet]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_LAY_TrangThaiDuyet]
@IDMucTieu bigint
AS
BEGIN
	----Kiểm tra chỉ tiêu đã bị duyệt đánh giá chưa
	--DECLARE @IDHTMT bigint;
	--DECLARE @IDHTTS bigint;
	--DECLARE @IDCoCau bigint;
	--DECLARE @IDNguoiPhuTrach bigint;
	--DECLARE @COUNT int=0;
	--SELECT @IDHTMT=IDHTMT,@IDHTTS=IDHTTS,@IDCoCau=IDCoCau,@IDNguoiPhuTrach=IDNguoiPhuTrach
	--FROM TW_MucTieu
	--WHERE IDMucTieu=@IDMucTieu;

	--IF @IDCoCau>0
	--BEGIN
	--	SELECT @COUNT=COUNT(*)
	--	FROM TW_DanhGia
	--	WHERE IDHTMT=@IDHTMT
	--	AND IDHTTS=@IDHTTS
	--	AND IDCoCau=@IDCoCau
	--	AND ISNULL(Khoa,0)=1;
	--END;
	--ELSE
	--BEGIN
	--	SELECT @COUNT=COUNT(*)
	--	FROM TW_DanhGia
	--	WHERE IDHTMT=@IDHTMT
	--	AND IDHTTS=@IDHTTS
	--	AND IDNguoiPhuTrach=@IDNguoiPhuTrach
	--	AND ISNULL(Khoa,0)=1;
	--END;
	--if @COUNT>0
	--BEGIN
	--	RETURN -99;--Đã duyệt đánh giá tổng hợp
	--END;

	--SELECT @COUNT=COUNT(*)
	--FROM TW_MucTieuNhapKetQua
	--WHERE IDMucTieu=@IDMucTieu
	--AND ISNULL(IDTrangThaiDuyet,0) not in (0,1);
	--if @COUNT>0
	--BEGIN
	--	RETURN -98;--Đã duyệt nhập kết quả
	--END;

	RETURN 0;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LAY_TrangThaiDuyetTongHop]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_LAY_TrangThaiDuyetTongHop]
@IDMucTieu bigint
AS
BEGIN
	--Kiểm tra chỉ tiêu đã bị duyệt đánh giá chưa
	DECLARE @IDHTMT bigint;
	DECLARE @IDHTTS bigint;
	DECLARE @IDCoCau bigint;
	DECLARE @IDNguoiPhuTrach bigint;
	DECLARE @COUNT int=0;
	SELECT @IDHTMT=IDHTMT,@IDHTTS=IDHTTS,@IDCoCau=IDCoCau,@IDNguoiPhuTrach=IDNguoiPhuTrach
	FROM TW_MucTieu
	WHERE IDMucTieu=@IDMucTieu;

	IF @IDCoCau>0
	BEGIN
		SELECT @COUNT=COUNT(*)
		FROM TW_DanhGia
		WHERE IDHTMT=@IDHTMT
		AND IDHTTS=@IDHTTS
		AND IDCoCau=@IDCoCau
		AND ISNULL(Khoa,0)=1;
	END;
	ELSE
	BEGIN
		SELECT @COUNT=COUNT(*)
		FROM TW_DanhGia
		WHERE IDHTMT=@IDHTMT
		AND IDHTTS=@IDHTTS
		AND IDNguoiPhuTrach=@IDNguoiPhuTrach
		AND ISNULL(Khoa,0)=1;
	END;
	if @COUNT>0
	BEGIN
		RETURN -99;--Đã duyệt đánh giá tổng hợp
	END;
	RETURN 0;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_Login]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_Login]
@UserName varchar(200)
AS
BEGIN
	SELECT * FROM SYS_NhanSu WHERE lower(DB_UserName)=lower(@UserName) and DB_UserName is not null 
	and ISNULL(trangthai,0)=1
	and ISNULL(IsDelete,0)=0;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_DanhGiaTongHop]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_DanhGiaTongHop]
@IDHTMT	bigint,
@IDDanhGia bigint,
@DiemDuyet decimal(5, 2),
@MucDuyet nvarchar(50),
@NhanXet nvarchar(512),
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Count int=0;
	DECLARE @CountMaDG int=0;

	SELECT @Count=Count(*) FROM TW_DanhGiaTongHop WHERE IDDanhGia=@IDDanhGia;

	SELECT @CountMaDG=Count(*) FROM TW_MucDanhGia WHERE UPPER(MaMucDanhGia)=UPPER(@MucDuyet) and ISNULL(IsDelete,0)=0;
	IF @CountMaDG=0 SET @MucDuyet=null;

	IF (@Count>0)
		UPDATE TW_DanhGiaTongHop 
		SET DiemDuyet=@DiemDuyet, MucDuyet=@MucDuyet,NhanXet=@NhanXet,
		LastUpdatedDate=getdate(), LastUpdatedBy=@IDNhanSu
		WHERE IDDanhGia=@IDDanhGia;
	ELSE
		INSERT INTO TW_DanhGiaTongHop
		(IDDanhGia,DiemDuyet,MucDuyet,NhanXet,LastUpdatedDate, LastUpdatedBy)
		VALUES
		(@IDDanhGia,@DiemDuyet,@MucDuyet,@NhanXet,getdate(), @IDNhanSu)
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_DoiMatKhau]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_DoiMatKhau]
@ID bigint,
@Email nvarchar(256),
@PassHienTai nvarchar(1000),
@PassMoi nvarchar(1000)
AS
BEGIN
	DECLARE @Count int=0;

	SELECT @Count=Count(*) FROM AspNetUsers WHERE ID=@ID and lower(Email)=lower(@Email) and PasswordHash=@PassHienTai;

	IF (@Count>0)
	BEGIN
		UPDATE AspNetUsers 
		SET PasswordHash=@PassMoi
		WHERE ID=@ID and lower(Email)=lower(@Email) and PasswordHash=@PassHienTai;
	END;
	return @Count;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_KhachHang]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_KhachHang]
@IDKhachHang int,
@Code nvarchar(200),
@Name nvarchar(2000),
@Email nvarchar(200),
@IsDisabled bit,
@IsDeleted bit,
@NgayDangKy datetime,
@NgayHieuLuc datetime,
@NgayHetHan	datetime,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Count int=0;
	IF(@IDKhachHang>0)
	BEGIN
		--UPDATE
		SELECT @Count=Count(*) FROM SYS_KhachHang WHERE LOWER(@Code)=LOWER(Code) AND IDKhachHang!=@IDKhachHang;
		IF @Count>0
		BEGIN
			RETURN -1;
		END;
		ELSE
		BEGIN
			UPDATE SYS_KhachHang 
			SET Code=@Code,
				Name=@Name,
				Email=@Email,
				IsDisabled=@IsDisabled,
				IsDeleted=@IsDeleted,
				NgayDangKy=@NgayDangKy,
				NgayHieuLuc=@NgayHieuLuc,
				NgayHetHan=@NgayHetHan,
				LastUpdatedBy=@IDNhanSu, 
				LastUpdatedDate=getdate()
			WHERE IDKhachHang!=@IDKhachHang;
		END;
	END;
	ELSE
	BEGIN
		--INSERT
		SELECT @Count=Count(*) FROM SYS_KhachHang WHERE LOWER(@Code)=LOWER(Code);
		IF @Count>0
		BEGIN
			RETURN -1;
		END;
		BEGIN
			INSERT INTO SYS_KhachHang 
			(IDKhachHang,Code,Name,Email,IsDisabled,IsDeleted,NgayDangKy,NgayHieuLuc,NgayHetHan,LastUpdatedBy,LastUpdatedDate)
			VALUES
			(@IDKhachHang,@Code,@Name,@Email,@IsDisabled,@IsDeleted,@NgayDangKy,@NgayHieuLuc,@NgayHetHan,@IDNhanSu,getdate());
		END;
	END;
	return 0;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_MucTieuPhanHoi]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_MucTieuPhanHoi]
@IDMucTieu	bigint,
@PhanHoi nvarchar(256),
@IDCapDuyet int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Date datetime=getdate();
	IF @IDCapDuyet=1
	BEGIN
		UPDATE TW_MucTieu
		SET PhanHoi1=@PhanHoi
		WHERE IDMucTieu=@IDMucTieu;

		select NgayDuyet1 as LastUpdateDate
		FROM TW_MucTieu
		WHERE IDMucTieu=@IDMucTieu;
	END;
	ELSE IF @IDCapDuyet=2
	BEGIN
		UPDATE TW_MucTieu
		SET PhanHoi2=@PhanHoi
		WHERE IDMucTieu=@IDMucTieu;

		select NgayDuyet2 as LastUpdateDate
		FROM TW_MucTieu
		WHERE IDMucTieu=@IDMucTieu;
	END;
	ELSE IF @IDCapDuyet=3
	BEGIN
		UPDATE TW_MucTieu
		SET PhanHoi3=@PhanHoi
		WHERE IDMucTieu=@IDMucTieu;

		select NgayDuyet3 as LastUpdateDate
		FROM TW_MucTieu
		WHERE IDMucTieu=@IDMucTieu;
	END;

END
GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_MucTieuPhanHoi_NhapKetQua]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_MucTieuPhanHoi_NhapKetQua]
@IDMucTieu	bigint,
@PhanHoi nvarchar(256),
@IDCapDuyet int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Count int=0;
	DECLARE @Date datetime=getdate();
	
	SELECT @Count=COUNT(*) FROM TW_MucTieuNhapKetQua WHERE IDMucTieu=@IDMucTieu;
	
	IF @Count=0
	BEGIN
		IF @IDCapDuyet=0
		BEGIN
			INSERT INTO TW_MucTieuNhapKetQua(IDMucTieu,ThuyetMinh,NguoiThuyetMinh,NgayThuyetMinh)
			VALUES (@IDMucTieu,@PhanHoi,@IDNhanSu,@Date)
		END;
		ELSE IF @IDCapDuyet=1
		BEGIN
			INSERT INTO TW_MucTieuNhapKetQua(IDMucTieu,PhanHoi1,NguoiDuyet1,NgayDuyet1)
			VALUES (@IDMucTieu,@PhanHoi,@IDNhanSu,@Date)
		END;
		ELSE IF @IDCapDuyet=2
		BEGIN
			INSERT INTO TW_MucTieuNhapKetQua(IDMucTieu,PhanHoi2,NguoiDuyet2,NgayDuyet2)
			VALUES (@IDMucTieu,@PhanHoi,@IDNhanSu,@Date)
		END;
		ELSE IF @IDCapDuyet=3
		BEGIN
			INSERT INTO TW_MucTieuNhapKetQua(IDMucTieu,PhanHoi3,NguoiDuyet3,NgayDuyet3)
			VALUES (@IDMucTieu,@PhanHoi,@IDNhanSu,@Date)
		END;
	END;
	ELSE
	BEGIN
		IF @IDCapDuyet=0
		BEGIN
			UPDATE TW_MucTieuNhapKetQua
			SET ThuyetMinh=@PhanHoi,
				NgayThuyetMinh=@Date,
				NguoiThuyetMinh=@IDNhanSu
			WHERE IDMucTieu=@IDMucTieu;

			select NgayThuyetMinh as LastUpdateDate
			FROM TW_MucTieuNhapKetQua
			WHERE IDMucTieu=@IDMucTieu;
		END;
		ELSE IF @IDCapDuyet=1
		BEGIN
			UPDATE TW_MucTieuNhapKetQua
			SET PhanHoi1=@PhanHoi,
				NgayDuyet1=@Date,
				NguoiDuyet1=@IDNhanSu
			WHERE IDMucTieu=@IDMucTieu;

			select NgayDuyet1 as LastUpdateDate
			FROM TW_MucTieuNhapKetQua
			WHERE IDMucTieu=@IDMucTieu;
		END;
		ELSE IF @IDCapDuyet=2
		BEGIN
			UPDATE TW_MucTieuNhapKetQua
			SET PhanHoi2=@PhanHoi,
				NgayDuyet2=@Date,
				NguoiDuyet2=@IDNhanSu
			WHERE IDMucTieu=@IDMucTieu;

			select NgayDuyet2 as LastUpdateDate
			FROM TW_MucTieuNhapKetQua
			WHERE IDMucTieu=@IDMucTieu;
		END;
		ELSE IF @IDCapDuyet=3
		BEGIN
			UPDATE TW_MucTieuNhapKetQua
			SET PhanHoi3=@PhanHoi,
				NgayDuyet3=@Date,
				NguoiDuyet3=@IDNhanSu
			WHERE IDMucTieu=@IDMucTieu;

			select NgayDuyet3 as LastUpdateDate
			FROM TW_MucTieuNhapKetQua
			WHERE IDMucTieu=@IDMucTieu;
		END;
	END;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_MucTieuTienDo]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_MucTieuTienDo]
@IDMucTieu	bigint,
@SoThucTeSo	decimal(18, 2),
@SoThucTeNgay	date,
@SoThucTeTyLe	decimal(7, 2),
@TyLeHoanThanh	decimal(5, 2),
@UpdateType tinyint,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @NgayTao datetime = getdate();
	DECLARE @Count int=0;
	DECLARE @TongTrongSo decimal(18,5);
	DECLARE @ChuThe bit=0;--Bộ phận

	--@UpdateType: 0: update all, 1:TyLeHoanThanh, 2:SoThucTeSo, 3: SoThucTeNgay, 4:SoThucTeTyLe
	IF @UpdateType=1
	BEGIN
		UPDATE TW_MucTieu
		SET TyLeTamTinh=@TyLeHoanThanh
		where IDMucTieu=@IDMucTieu;
	END;
	
	SELECT @Count=COUNT(*) FROM TW_MucTieuNhapKetQua WHERE IDMucTieu=@IDMucTieu;
	IF @Count>0
	BEGIN
		IF @UpdateType=2
		BEGIN
			UPDATE TW_MucTieuNhapKetQua SET SoThucTeSo=@SoThucTeSo, LastUpdatedDate=@NgayTao,LastUpdatedBy=@IDNhanSu WHERE IDMucTieu=@IDMucTieu;
		END;
		IF @UpdateType=3
		BEGIN
			UPDATE TW_MucTieuNhapKetQua SET SoThucTeNgay=@SoThucTeNgay, LastUpdatedDate=@NgayTao,LastUpdatedBy=@IDNhanSu WHERE IDMucTieu=@IDMucTieu;
		END;
		IF @UpdateType=4
		BEGIN
			UPDATE TW_MucTieuNhapKetQua SET SoThucTeTyLe=@SoThucTeTyLe, LastUpdatedDate=@NgayTao,LastUpdatedBy=@IDNhanSu WHERE IDMucTieu=@IDMucTieu;
		END;
	END;
	ELSE
	BEGIN
		INSERT INTO TW_MucTieuNhapKetQua
		(IDMucTieu,SoThucTeSo,SoThucTeNgay,SoThucTeTyLe,LastUpdatedDate,LastUpdatedBy)
		VALUES
		(@IDMucTieu,@SoThucTeSo,@SoThucTeNgay,@SoThucTeTyLe,@NgayTao,@IDNhanSu);
	END;

	select IDMucTieu,CTDiemChiTieu,SoKeHoachNgay as SoThucTeNgay, SoKeHoachSo as SoThucTeSo, SoKeHoachTyLe as SoThucTeTyLe, ISNULL(TyleHoanThanh,TyLeTamTinh) as TyleHoanThanh
	FROM TW_MucTieu where IDMucTieu=@IDMucTieu;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_MucTieuTrangThai]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_MucTieuTrangThai]
@IDMucTieu	bigint,
@IDTrangThaiMucTieu	tinyint,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @NgayTao datetime = getdate();
	
	UPDATE TW_MucTieu SET IDTrangThaiMucTieu=@IDTrangThaiMucTieu WHERE IDMucTieu=@IDMucTieu and ISNULL(IsDelete,0)=0 AND ISNULL(Dong,0)=0;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_MucTieuTyLeHoanThanh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_MucTieuTyLeHoanThanh]
@IDMucTieu	bigint,
@TyLeHoanThanh	decimal(5, 2),
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Count int=0;
	SELECT @Count=COUNT(*) 
	FROM TW_MucTieuNhapKetQua
	WHERE IDMucTieu=@IDMucTieu
	AND IDTrangThaiDuyet in (4,7,10);--Chỉ tiêu đã duyệt

	IF @Count>0 RETURN -1;--Chỉ tiêu đã duyệt

	SELECT @Count=COUNT(*) 
	FROM TW_MucTieuNhapKetQua nkq
	INNER JOIN TW_MucTieu mt on mt.IDMucTieu=nkq.IDMucTieu
	INNER JOIN TW_DonViTinh dv on dv.IDDonViTinh=mt.IDDonViTinh
	WHERE nkq.IDMucTieu=@IDMucTieu
	AND (
			(dv.IDKieuDuLieu=1 AND (nkq.SoThucTeSo1 is not null OR nkq.SoThucTeSo2 is not null OR nkq.SoThucTeSo3 is not null))
			OR (dv.IDKieuDuLieu=2 AND (nkq.SoThucTeNgay1 is not null OR nkq.SoThucTeNgay2 is not null OR nkq.SoThucTeNgay3 is not null))
			OR (dv.IDKieuDuLieu=3 AND (nkq.SoThucTeTyLe1 is not null OR nkq.SoThucTeTyLe2 is not null OR nkq.SoThucTeTyLe3 is not null))
		);

	IF @Count>0 RETURN -2;--Chỉ tiêu đã nhập kết quả đánh giá

	UPDATE TW_MucTieu
	SET TyLeTamTinh=@TyLeHoanThanh
	where IDMucTieu=@IDMucTieu;

	return 0;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_NhapKetQua]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_NhapKetQua]
@IDHTMT	bigint = null,
@IDMucTieu bigint,
@IDNguoiPhuTrach bigint,
@SoThucTeSo decimal(18, 2),
@SoThucTeNgay date,
@SoThucTeTyLe decimal(7, 2),
@SoThucTeSo1 decimal(18, 2),
@SoThucTeNgay1 date,
@SoThucTeTyLe1 decimal(7, 2),
@SoThucTeSo2 decimal(18, 2),
@SoThucTeNgay2 date,
@SoThucTeTyLe2 decimal(7, 2),
@SoThucTeSo3 decimal(18, 2),
@SoThucTeNgay3 date,
@SoThucTeTyLe3 decimal(7, 2),
@stt int,
@TyLeHoanThanh	decimal(7, 2),
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Count int=0;
	DECLARE @Date date=getdate();

	--Update trang thai Muc Tieu
	Update TW_MucTieu set IDTrangThaiMucTieu=2 WHERE IDMucTieu=@IDMucTieu AND ISNULL(IDTrangThaiMucTieu,0)<2;--Chuyển trạng thái đang làm
	DECLARE @IDTrangThaiDuyet tinyint;

	IF (@IDMucTieu>0)
	BEGIN
		SELECT @Count=Count(*) FROM TW_MucTieuNhapKetQua WHERE IDMucTieu=@IDMucTieu;
		IF (@Count>0)
		BEGIN
			SELECT @IDTrangThaiDuyet=ISNULL(IDTrangThaiDuyet,1) FROM TW_MucTieuNhapKetQua WHERE IDMucTieu=@IDMucTieu;
			if (@stt=0)
			BEGIN
				BEGIN
					IF @IDTrangThaiDuyet=10 RETURN -10;--Đã duyệt cấp 3
					IF @IDTrangThaiDuyet=8 RETURN -8;--Không duyệt cấp 3
					IF @IDTrangThaiDuyet=7 RETURN -7;--Đã duyệt cấp 2
					IF @IDTrangThaiDuyet=5 RETURN -5;--Không duyệt cấp 2
					IF @IDTrangThaiDuyet=4 RETURN -4;--Đã duyệt cấp 1
					IF @IDTrangThaiDuyet=2 RETURN -2;--Không duyệt cấp 1

					UPDATE TW_MucTieuNhapKetQua 
					SET SoThucTeSo=@SoThucTeSo, 
						SoThucTeNgay=@SoThucTeNgay, 
						SoThucTeTyLe=@SoThucTeTyLe,
						LastUpdatedDate=getdate(),
						LastUpdatedBy=@IDNhanSu
					WHERE IDMucTieu=@IDMucTieu;
				END;
			END
			if (@stt=1)
			BEGIN
				BEGIN
					UPDATE TW_MucTieuNhapKetQua 
					SET SoThucTeSo1=@SoThucTeSo1, 
						SoThucTeNgay1=@SoThucTeNgay1, 
						SoThucTeTyLe1=@SoThucTeTyLe1,
						NgayDuyet1=getdate(),
						NguoiDuyet1=@IDNhanSu
					WHERE IDMucTieu=@IDMucTieu;
				END;
			END
			if (@stt=2)
			BEGIN
				BEGIN
					UPDATE TW_MucTieuNhapKetQua 
					SET SoThucTeSo2=@SoThucTeSo2, 
						SoThucTeNgay2=@SoThucTeNgay2, 
						SoThucTeTyLe2=@SoThucTeTyLe2,
						NgayDuyet2=getdate(),
						NguoiDuyet2=@IDNhanSu
					WHERE IDMucTieu=@IDMucTieu AND ISNULL(IDTrangThaiDuyet2,0)=0;
				END;
			END
			if (@stt=3)
			BEGIN
				BEGIN
					UPDATE TW_MucTieuNhapKetQua 
					SET SoThucTeSo3=@SoThucTeSo3, 
						SoThucTeNgay3=@SoThucTeNgay3, 
						SoThucTeTyLe3=@SoThucTeTyLe3,
						NgayDuyet3=getdate(),
						NguoiDuyet3=@IDNhanSu
					WHERE IDMucTieu=@IDMucTieu AND ISNULL(IDTrangThaiDuyet3,0)=0;
				END;
			END
		END
		ELSE
			INSERT INTO TW_MucTieuNhapKetQua
			(IDMucTieu,SoThucTeSo,SoThucTeNgay,SoThucTeTyLe,SoThucTeSo1,SoThucTeNgay1,SoThucTeTyLe1,SoThucTeSo2,SoThucTeNgay2,SoThucTeTyLe2,SoThucTeSo3,SoThucTeNgay3,SoThucTeTyLe3,LastUpdatedDate,LastUpdatedBy)
			VALUES
			(@IDMucTieu,@SoThucTeSo,@SoThucTeNgay,@SoThucTeTyLe,@SoThucTeSo1,@SoThucTeNgay1,@SoThucTeTyLe1,@SoThucTeSo2,@SoThucTeNgay2,@SoThucTeTyLe2,@SoThucTeSo3,@SoThucTeNgay3,@SoThucTeTyLe3,getdate(),@IDNhanSu)
	
		UPDATE TW_MucTieu
		SET TyLeHoanThanh=@TyLeHoanThanh
		WHERE IDMucTieu=@IDMucTieu;
	END;
	return 0;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_LUU_ThietLap_TrongSo]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_LUU_ThietLap_TrongSo]
@IDHTMT	bigint,
@IDHTTS	bigint,
@IDMucTieu bigint,
@IDCoCau bigint,
@IDNguoiPhuTrach bigint,
@TrongSo decimal(5, 2),
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @Count int=0;

	Update TW_MucTieu SET TrongSo=@TrongSo, LastUpdatedDate=getdate(), LastUpdatedBy=@IDNhanSu
	WHERE IDHTMT=@IDHTMT AND IDMucTieu=@IDMucTieu;

	--IF (@IDMucTieu>0)
	--BEGIN
	--	SELECT @Count=Count(*) FROM TW_MucTieuTrongSo WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS and IDMucTieu=@IDMucTieu and IDCoCau=ISNULL(@IDCoCau,0) and IDNguoiPhuTrach=ISNULL(IDNguoiPhuTrach,0);
	--	IF (@Count>0)
	--		UPDATE TW_MucTieuTrongSo 
	--		SET TrongSo=@TrongSo, LastUpdatedDate=getdate(), LastUpdatedBy=@IDNhanSu
	--		WHERE IDHTMT=@IDHTMT and IDHTTS=@IDHTTS and IDMucTieu=@IDMucTieu AND ISNULL(DaDuyet,0)=0  and IDCoCau=ISNULL(@IDCoCau,0) and IDNguoiPhuTrach=ISNULL(IDNguoiPhuTrach,0);
	--	ELSE
	--		INSERT INTO TW_MucTieuTrongSo
	--		(IDHTMT,IDHTTS,IDMucTieu,IDCoCau,IDNguoiPhuTrach,TrongSo,LastUpdatedDate, LastUpdatedBy)
	--		VALUES
	--		(@IDHTMT,@IDHTTS,@IDMucTieu,ISNULL(@IDCoCau,0),ISNULL(@IDNguoiPhuTrach,0),@TrongSo,getdate(),@IDNhanSu);
	--END;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_QUYEN_MucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_QUYEN_MucTieu]
@IDMucTieu bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @QuyenUser tinyint=0;
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	--1: nhân sự, 2: Quản lý, 3: Bộ phận, 4: Chỉ định BP, 5: Toàn quyền
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4--Khong xem BP con
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);

	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND mt.IDMucTieu=@IDMucTieu
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	SELECT COUNT(*) AS QuyenUser
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND mt.IDMucTieu=@IDMucTieu
	AND ISNULL(mt.IDTrangThaiDuyet,0) in (0,1,3,6,9)
	AND htmt.IDKhachHang=@IDKhachHang;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_QUYEN_MucTieuImport]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_QUYEN_MucTieuImport]
@IDHTMT bigint,
@IDHTTS bigint,--Ky dữ liệu
@MaMucTieu nvarchar(100),
@TenMucTieu nvarchar(2000),
@IDCoCau bigint,--Chủ thể chỉ tiêu
@IDNguoiPhuTrach bigint,
@IDNhanSu bigint,
@IDChucNang int,
@IDKhachHang int
AS
BEGIN
	DECLARE @Count int, @IDMucTieu bigint;

	--Kiểm tra trùng mã chỉ tiêu
	SELECT @Count=COUNT(*) FROM TW_MucTieu 
	WHERE IDHTMT=@IDHTMT AND Lower(MaMucTieu)=Lower(@MaMucTieu) AND ISNULL(IsDelete,0)=0
	AND (IDHTTS!=@IDHTTS OR IDCoCau!=@IDCoCau OR IDNguoiPhuTrach!=@IDNguoiPhuTrach);
	--AND (Lower(TenMucTieu)!=Lower(@TenMucTieu) OR IDHTTS!=@IDHTTS OR IDCoCau!=@IDCoCau OR IDNguoiPhuTrach!=@IDNguoiPhuTrach)
	IF(@Count>0)
	BEGIN
		SELECT TOP 1 mt.*, npt.MaNhanSu ,npt.HoVaTen as TenNhanSu,cc.MaCoCau,cc.TenCoCau,
		-1 as QuyenUser--Trùng mã chỉ tiêu
		FROM TW_MucTieu mt
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
		LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=npt.IDChucDanh
		WHERE mt.IDHTMT=@IDHTMT AND Lower(mt.MaMucTieu)=Lower(@MaMucTieu) AND ISNULL(mt.IsDelete,0)=0
		AND (mt.IDHTTS!=@IDHTTS OR mt.IDCoCau!=@IDCoCau OR mt.IDNguoiPhuTrach!=@IDNguoiPhuTrach)
		--AND (Lower(mt.TenMucTieu)!=Lower(@TenMucTieu) OR mt.IDHTTS!=@IDHTTS OR mt.IDCoCau!=@IDCoCau OR mt.IDNguoiPhuTrach!=@IDNguoiPhuTrach)
		RETURN;
	END;
	ELSE
	BEGIN
		SELECT @IDMucTieu=IDMucTieu FROM TW_MucTieu 
		WHERE IDHTMT=@IDHTMT AND Lower(MaMucTieu)=Lower(@MaMucTieu) AND ISNULL(IsDelete,0)=0
		--AND Lower(TenMucTieu)=Lower(@TenMucTieu) 
		AND IDHTTS=@IDHTTS 
		AND IDCoCau=@IDCoCau 
		AND IDNguoiPhuTrach=@IDNguoiPhuTrach;
	END;

	DECLARE @QuyenUser tinyint=0;
	DECLARE @IDQuyen int, @dsQuyenBoPhan varchar(2000);
	select @IDQuyen=DataType,@dsQuyenBoPhan=dsQuyenBoPhan from SYS_PhanQuyen where IDNhanSu=@IDNhanSu and actionid=@IDChucNang;

	DECLARE @TableID TABLE(id bigint NOT NULL);
	DECLARE @Q_IDCoCau bigint,@Q_IDChucDanh bigint,@CayThuMuc nvarchar(256),@CayThuMucBP nvarchar(256);
	--IF @IDCoCauBP is not null 
	--BEGIN
	--	SELECT @CayThuMucBP=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@IDCoCauBP;
	--END;

	SELECT @Q_IDCoCau=IDCoCau,@Q_IDChucDanh=IDChucDanh FROM SYS_NhanSu WHERE IDNhanSu=@IDNhanSu;
	
	--1: nhân sự, 2: Quản lý, 3: Bộ phận, 4: Chỉ định BP, 5: Toàn quyền
	IF @IDQuyen=1
	INSERT INTO @TableID (id) VALUES (@IDNhanSu);
		
	IF @IDQuyen=2 OR @IDQuyen=3
	BEGIN
		SELECT @CayThuMuc=CayThuMuc FROM SYS_CoCau WHERE IDCoCau=@Q_IDCoCau;
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and CayThuMuc like @CayThuMuc+'%';

		DECLARE @TableKiemNhiem TABLE(CayThuMuc nvarchar(256), STT int);
		--Them Chuc Danh kiem nhiem
		INSERT INTO @TableKiemNhiem(CayThuMuc,STT)
		SELECT cc.CayThuMuc,ROW_NUMBER() OVER(ORDER BY cc.IDCoCau) AS STT
		FROM SYS_NhanSu ns
		INNER JOIN SYS_KiemNhiem kn on kn.DB_IDNhanSu=ns.DB_IDNhanSu
		INNER JOIN SYS_ChucDanh cd on cd.DB_IDChucDanh=kn.DB_IDChucDanh
		INNER JOIN SYS_CoCau cc on cc.IDCoCau=cd.IDCoCau
		WHERE ns.IDNhanSu=@IDNhanSu;

		DECLARE @cnt int=1,@cnt_total int=0;
		SELECT @cnt_total=COUNT(*) FROM @TableKiemNhiem;
		WHILE @cnt <= @cnt_total
		BEGIN
			SELECT @CayThuMuc=CayThuMuc FROM @TableKiemNhiem WHERE STT=@cnt;
			IF @CayThuMuc IS NOT NULL 
				INSERT INTO @TableID (id) 
				SELECT cc.IDCoCau 
				from SYS_CoCau cc
				LEFT JOIN @TableID tmp on tmp.id=cc.IDCoCau
				where cc.IDKhachHang=@IDKhachHang
				AND tmp.id is null
				and cc.CayThuMuc like @CayThuMuc+'%';
		    SET @cnt = @cnt + 1;
		END;
	END;

	IF @IDQuyen=4--Khong xem BP con
	BEGIN
		INSERT INTO @TableID (id)
		SELECT IDCoCau from SYS_CoCau where IDKhachHang=@IDKhachHang and ','+@dsQuyenBoPhan+',' like '%,'+CAST(DB_IDCoCau as varchar(30))+',%';
	END;

	--Theo chỉ tiêu
	DECLARE @TableChiTieu TABLE(IDMucTieu bigint, CapBac tinyint);

	IF @IDQuyen!=5
	BEGIN
		--Lấy ds chỉ tiêu đảm nhiệm
		INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
		SELECT mt.IDMucTieu, mt.CapBac
		from TW_MucTieu mt 
		INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
		LEFT JOIN SYS_CoCau cc on cc.IDCoCau=mt.IDCoCau
		where htmt.IDKhachHang=@IDKhachHang
		AND mt.IDNguoiPhuTrach = @IDNhanSu and mt.CayThuMuc is not null
		AND htmt.SuDung=1
		AND (@IDMucTieu is null or mt.IDMucTieu=@IDMucTieu)
		--Lấy ds chỉ tiêu con của chỉ tiêu đảm nhiệm
		DECLARE @MaxCap int=20;--20 cấp
		IF @MaxCap>0
		BEGIN
			DECLARE @i int = 0;
			WHILE @i <= @MaxCap
			BEGIN
				SET @i = @i + 1;
				INSERT INTO @TableChiTieu (IDMucTieu, CapBac)
				SELECT mt.IDMucTieu, mt.CapBac
				from TW_MucTieu mt
				WHERE ISNULL(mt.IsDelete,0)=0
				AND mt.IDMucTieuCha in (select IDMucTieu from @TableChiTieu where CapBac=@i)
				AND mt.IDMucTieu not in (select IDMucTieu from @TableChiTieu where CapBac=@i+1);
			END
		END;
	END;

	SELECT COUNT(*) AS QuyenUser
	from TW_MucTieu mt 
	INNER JOIN TW_HeThongMucTieu htmt on htmt.IDHTMT=mt.IDHTMT
	LEFT JOIN SYS_NhanSu npt on npt.IDNhanSu=mt.IDNguoiPhuTrach
	LEFT JOIN SYS_ChucDanh cd on cd.IDChucDanh=mt.IDChucDanh
	--Kiểm tra Quyền chỉ tiêu cha con
	LEFT JOIN @TableChiTieu QCT ON mt.IDMucTieu=QCT.IDMucTieu
	where htmt.IDKhachHang=@IDKhachHang AND htmt.SuDung=1
	AND (@IDQuyen=5 
		OR (@IDQuyen!=5 AND 
				(QCT.IDMucTieu is not null
					OR
					(
						(@IDQuyen=1 AND mt.IDNguoiPhuTrach in (select id from @TableID))
						OR (@IDQuyen in (2,3,4) AND (mt.IDCoCau in (select id from @TableID) OR npt.IDCoCau in (select id from @TableID) OR cd.IDCoCau in (select id from @TableID)))
					)
				)
			)
		)
	AND (@IDMucTieu is null or mt.IDMucTieu=@IDMucTieu)
	AND htmt.IDKhachHang=@IDKhachHang;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_SUA_MucTieu_FileDinhKem]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_SUA_MucTieu_FileDinhKem]
@IDMucTieu bigint,
@FileDinhKem tinyint,
@IDNhanSu bigint,
@IDKhachHang int
AS
BEGIN
	UPDATE TW_MucTieu 
	set FileDinhKem=@FileDinhKem
	WHERE IDMucTieu=@IDMucTieu;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_SUA_MucTieuTask]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_SUA_MucTieuTask]
@IDTask	bigint,
@IDMucTieu	bigint,
@TenTask	nvarchar(128),
@KyHan	date,
@HoanThanh bit,
@UpdateType	tinyint,
@IDNhanSu bigint
AS
BEGIN
	DECLARE @Count int=0;
	IF @UpdateType=1
	BEGIN
		UPDATE TW_MucTieuTask
		SET TenTask=@TenTask
		WHERE IDTask=@IDTask;
	END;
	ELSE IF @UpdateType=2
	BEGIN
		UPDATE TW_MucTieuTask
		SET KyHan=@KyHan
		WHERE IDTask=@IDTask;
	END;
	ELSE IF @UpdateType=3
	BEGIN
		UPDATE TW_MucTieuTask
		SET HoanThanh=@HoanThanh
		WHERE IDTask=@IDTask;
	END;
END


GO
/****** Object:  StoredProcedure [dbo].[sp_THEM_MucTieuTask]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_THEM_MucTieuTask]
@IDTask	bigint,
@IDMucTieu	bigint,
@TenTask	nvarchar(128),
@KyHan	date,
@UpdateType	tinyint,
@IDNhanSu bigint
AS
BEGIN
	INSERT INTO TW_MucTieuTask (IDMucTieu,TenTask,KyHan,HoanThanh,IDNhanSu) VALUES (@IDMucTieu,@TenTask,@KyHan,0,@IDNhanSu);
	SELECT @IDTask = SCOPE_IDENTITY();
	SELECT * FROM TW_MucTieuTask WHERE IDTask=@IDTask;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_ChucDanh_SapXep]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_THI_ChucDanh_SapXep]
@IDChucDanh bigint,
@IDChaOld bigint,
@IDCha bigint,
@IDNhanSu bigint,
@IDKhachHang int
AS
BEGIN
	DELETE from TMP_ChucDanhThuMuc;
	DECLARE @NgayTao datetime = getdate();
	DECLARE @Count int=0, @Count1 int=0, @Count2 int=0, @CapBac tinyint=0;
	
	--Cập nhật trạng thái Mục Tiêu Cha cũ
	if(@IDChaOld is not null)
	BEGIN
		SELECT @Count=Count(*) FROM SYS_ChucDanh WHERE IDCha=@IDChaOld and ISNULL(IsDelete,0)=0 AND IDKhachHang=@IDKhachHang;
		IF (@Count>0)
			UPDATE SYS_ChucDanh SET CoLopCon=1 WHERE IDChucDanh=@IDChaOld and ISNULL(IsDelete,0)=0 AND IDKhachHang=@IDKhachHang;
		ELSE
			UPDATE SYS_ChucDanh SET CoLopCon=0 WHERE IDChucDanh=@IDChaOld and ISNULL(IsDelete,0)=0 AND IDKhachHang=@IDKhachHang;
	END;

	----Cập nhật trạng thái Mục Tiêu Cha mới
	UPDATE SYS_ChucDanh SET CoLopCon=1 WHERE IDChucDanh=@IDCha and ISNULL(IsDelete,0)=0 AND IDKhachHang=@IDKhachHang;

	--Lớp 1 Thêm bản thân cơ cấu vào bảng tạm
	IF ISNULL(@IDCha,0)=0
		BEGIN
			INSERT INTO TMP_ChucDanhThuMuc (IDChucDanh,IDNhanSuLoad,NgayTao,IDCha,IDKhachHang,CoLopCon,CapBac,CayThuMuc,MaThuMuc)
										--(IDHTMT,IDMucTieu,IDMucTieuCha,IDNhanSuLoad,NgayTao,CoLopCon,CapBac,CayThuMuc)
			SELECT cc.IDChucDanh,@IDNhanSu,@NgayTao,cc.IDCha,@IDKhachHang,0,1,';'+cast(cc.IDChucDanh as varchar(20))+';',';'+cc.MaChucDanh+';'
			FROM SYS_ChucDanh cc
			WHERE cc.IDKhachHang=@IDKhachHang AND ISNULL(cc.IsDelete,0)=0 AND cc.IDChucDanh = @IDChucDanh;
		END;
	ELSE
		BEGIN
			INSERT INTO TMP_ChucDanhThuMuc (IDChucDanh,IDNhanSuLoad,NgayTao,IDCha,IDKhachHang,CoLopCon,CapBac,CayThuMuc,MaThuMuc)
			SELECT cc.IDChucDanh,@IDNhanSu,@NgayTao,cc.IDCha,@IDKhachHang,0,ISNULL(tmp.CapBac,0)+1,ISNULL(tmp.CayThuMuc,';')+cast(cc.IDChucDanh as varchar(20))+';',ISNULL(tmp.MaThuMuc,';')+cc.MaChucDanh+';'
			FROM SYS_ChucDanh cc
			INNER JOIN SYS_ChucDanh tmp on cc.IDKhachHang=tmp.IDKhachHang AND tmp.IDChucDanh=cc.IDCha
			WHERE cc.IDKhachHang=@IDKhachHang AND ISNULL(cc.IsDelete,0)=0 AND cc.IDChucDanh=@IDChucDanh;
		END;

	SELECT @Count2=COUNT(*),@CapBac=MAX(CapBac) FROM TMP_ChucDanhThuMuc WHERE IDKhachHang=@IDKhachHang AND IDNhanSuLoad=@IDNhanSu AND NgayTao=@NgayTao;
	SET @Count1=@Count2;
	
	IF @CapBac>9 GOTO CapNhatChucDanh;

	--Lớp 2 + n = Thêm n lớp con
	DECLARE @i int = 2
	DECLARE @MaxLevel int = 99;
	WHILE @i < @MaxLevel
	BEGIN
		SET @i = @i + 1
		INSERT INTO TMP_ChucDanhThuMuc (IDChucDanh,IDNhanSuLoad,NgayTao,IDCha,IDKhachHang,CoLopCon,CapBac,CayThuMuc,MaThuMuc)
		SELECT cc.IDChucDanh,@IDNhanSu,@NgayTao,cc.IDCha,cc.IDKhachHang,cc.CoLopCon,ISNULL(tmp.CapBac,0)+1,ISNULL(tmp.CayThuMuc,';')+cast(cc.IDChucDanh as varchar(20))+';',ISNULL(tmp.MaThuMuc,';')+cc.MaChucDanh+';'
		FROM SYS_ChucDanh cc
		INNER JOIN TMP_ChucDanhThuMuc tmp on cc.IDKhachHang=tmp.IDKhachHang AND tmp.IDNhanSuLoad=@IDNhanSu AND tmp.NgayTao=@NgayTao AND tmp.IDChucDanh=cc.IDCha and tmp.CapBac=@CapBac
		WHERE cc.IDKhachHang=@IDKhachHang AND ISNULL(cc.IsDelete,0)=0 AND ISNULL(cc.IDCha,0) = tmp.IDChucDanh;

		SELECT @Count2=COUNT(*), @CapBac=@CapBac+1 FROM TMP_ChucDanhThuMuc WHERE IDkhachHang=@IDkhachHang AND IDNhanSuLoad=@IDNhanSu AND NgayTao=@NgayTao;
		IF @Count2=@Count1 OR @CapBac>@MaxLevel
		BEGIN
			SET @i=@MaxLevel+2;
			GOTO CapNhatChucDanh;
		END;
		SET @Count1=@Count2;
	END

	CapNhatChucDanh: 
		UPDATE TMP_ChucDanhThuMuc 
		SET CoLopCon=1
		FROM (SELECT DISTINCT IDKhachHang, IDCha
			FROM TMP_ChucDanhThuMuc) AS OtherTable
		WHERE TMP_ChucDanhThuMuc.IDChucDanh=OtherTable.IDCha
		AND TMP_ChucDanhThuMuc.IDKhachHang=OtherTable.IDKhachHang;

		UPDATE SYS_ChucDanh 
		SET CoLopCon = OtherTable.CoLopCon, 
		    CapBac = OtherTable.CapBac, 
			CayThuMuc = OtherTable.CayThuMuc ,
			MaThuMuc = UPPER(OtherTable.MaThuMuc)
		FROM (SELECT * 
			FROM TMP_ChucDanhThuMuc) AS OtherTable
		WHERE SYS_ChucDanh.IDChucDanh=OtherTable.IDChucDanh
		AND SYS_ChucDanh.IDKhachHang=OtherTable.IDKhachHang;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_CoCau_SapXep]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_THI_CoCau_SapXep]
@IDCoCau bigint,
@IDChaOld bigint,
@IDCha bigint,
@IDNhanSu bigint,
@IDKhachHang int
AS
BEGIN
	DELETE from TMP_CoCauThuMuc;
	DECLARE @NgayTao datetime = getdate();
	DECLARE @Count int=0, @Count1 int=0, @Count2 int=0, @CapBac tinyint=0;
	
	--Cập nhật trạng thái Mục Tiêu Cha cũ
	if(@IDChaOld is not null)
	BEGIN
		SELECT @Count=Count(*) FROM SYS_CoCau WHERE IDCha=@IDChaOld and ISNULL(IsDelete,0)=0 AND IDKhachHang=@IDKhachHang;
		IF (@Count>0)
			UPDATE SYS_CoCau SET CoLopCon=1 WHERE IDCoCau=@IDChaOld and ISNULL(IsDelete,0)=0 AND IDKhachHang=@IDKhachHang;
		ELSE
			UPDATE SYS_CoCau SET CoLopCon=0 WHERE IDCoCau=@IDChaOld and ISNULL(IsDelete,0)=0 AND IDKhachHang=@IDKhachHang;
	END;

	----Cập nhật trạng thái Mục Tiêu Cha mới
	UPDATE SYS_CoCau SET CoLopCon=1 WHERE IDCoCau=@IDCha and ISNULL(IsDelete,0)=0 AND IDKhachHang=@IDKhachHang;

	--Lớp 1 Thêm bản thân cơ cấu vào bảng tạm
	IF ISNULL(@IDCha,0)=0
		BEGIN
			INSERT INTO TMP_CoCauThuMuc (IDCoCau,IDNhanSuLoad,NgayTao,IDCha,IDKhachHang,CoLopCon,CapBac,CayThuMuc,MaThuMuc)
										--(IDHTMT,IDMucTieu,IDMucTieuCha,IDNhanSuLoad,NgayTao,CoLopCon,CapBac,CayThuMuc)
			SELECT cc.IDCoCau,@IDNhanSu,@NgayTao,cc.IDCha,@IDKhachHang,0,1,';'+cast(cc.IDCoCau as varchar(20))+';',';'+ISNULL(cast(cc.ThuTu as varchar(20)),'0')+'_'+cc.MaCoCau+';'
			FROM SYS_CoCau cc
			WHERE cc.IDKhachHang=@IDKhachHang AND ISNULL(cc.IsDelete,0)=0 AND cc.IDCoCau = @IDCoCau;
		END;
	ELSE
		BEGIN
			INSERT INTO TMP_CoCauThuMuc (IDCoCau,IDNhanSuLoad,NgayTao,IDCha,IDKhachHang,CoLopCon,CapBac,CayThuMuc,MaThuMuc)
			SELECT cc.IDCoCau,@IDNhanSu,@NgayTao,cc.IDCha,@IDKhachHang,0,ISNULL(tmp.CapBac,0)+1,ISNULL(tmp.CayThuMuc,';')+cast(cc.IDCoCau as varchar(20))+';',ISNULL(tmp.MaThuMuc,';')+';'+ISNULL(cast(cc.ThuTu as varchar(20)),'0')+'_'+cc.MaCoCau+';'
			FROM SYS_CoCau cc
			INNER JOIN SYS_CoCau tmp on cc.IDKhachHang=tmp.IDKhachHang AND tmp.IDCoCau=cc.IDCha
			WHERE cc.IDKhachHang=@IDKhachHang AND ISNULL(cc.IsDelete,0)=0 AND cc.IDCoCau=@IDCoCau;
		END;

	SELECT @Count2=COUNT(*),@CapBac=MAX(CapBac) FROM TMP_CoCauThuMuc WHERE IDKhachHang=@IDKhachHang AND IDNhanSuLoad=@IDNhanSu AND NgayTao=@NgayTao;
	SET @Count1=@Count2;
	
	IF @CapBac>9 GOTO CapNhatCocau;

	--Lớp 2 + n = Thêm n lớp con
	DECLARE @i int = 2
	DECLARE @MaxLevel int = 99;
	WHILE @i < @MaxLevel
	BEGIN
		SET @i = @i + 1
		INSERT INTO TMP_CoCauThuMuc (IDCoCau,IDNhanSuLoad,NgayTao,IDCha,IDKhachHang,CoLopCon,CapBac,CayThuMuc,MaThuMuc)
		SELECT cc.IDCoCau,@IDNhanSu,@NgayTao,cc.IDCha,cc.IDKhachHang,cc.CoLopCon,ISNULL(tmp.CapBac,0)+1,ISNULL(tmp.CayThuMuc,';')+cast(cc.IDCoCau as varchar(20))+';',ISNULL(tmp.MaThuMuc,';')+';'+ISNULL(cast(cc.ThuTu as varchar(20)),'0')+'_'+cc.MaCoCau+';'
		FROM SYS_CoCau cc
		INNER JOIN TMP_CoCauThuMuc tmp on cc.IDKhachHang=tmp.IDKhachHang AND tmp.IDNhanSuLoad=@IDNhanSu AND tmp.NgayTao=@NgayTao AND tmp.IDCoCau=cc.IDCha and tmp.CapBac=@CapBac
		WHERE cc.IDKhachHang=@IDKhachHang AND ISNULL(cc.IsDelete,0)=0 AND ISNULL(cc.IDCha,0) = tmp.IDCoCau;

		SELECT @Count2=COUNT(*), @CapBac=@CapBac+1 FROM TMP_CoCauThuMuc WHERE IDkhachHang=@IDkhachHang AND IDNhanSuLoad=@IDNhanSu AND NgayTao=@NgayTao;
		IF @Count2=@Count1 OR @CapBac>@MaxLevel
		BEGIN
			SET @i=@MaxLevel+2;
			GOTO CapNhatCocau;
		END;
		SET @Count1=@Count2;
	END

	CapNhatCocau: 
		UPDATE TMP_CoCauThuMuc 
		SET CoLopCon=1
		FROM (SELECT DISTINCT IDKhachHang, IDCha
			FROM TMP_CoCauThuMuc) AS OtherTable
		WHERE TMP_CoCauThuMuc.IDCoCau=OtherTable.IDCha
		AND TMP_CoCauThuMuc.IDKhachHang=OtherTable.IDKhachHang;

		UPDATE SYS_CoCau 
		SET CoLopCon = OtherTable.CoLopCon, 
		    CapBac = OtherTable.CapBac, 
			CayThuMuc = OtherTable.CayThuMuc ,
			MaThuMuc = UPPER(OtherTable.MaThuMuc)
		FROM (SELECT * 
			FROM TMP_CoCauThuMuc) AS OtherTable
		WHERE SYS_CoCau.IDCoCau=OtherTable.IDCoCau
		AND SYS_CoCau.IDKhachHang=OtherTable.IDKhachHang;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_LoaiMucTieu_KhoiTao]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_THI_LoaiMucTieu_KhoiTao]
@IDHTMT	bigint = null,
@IDNhanSu bigint,
@Overwrite bit=0
AS
BEGIN
	DECLARE @COUNT int=0;
	SELECT @COUNT=COUNT(*) FROM TW_LoaiMucTieu WHERE IDHTMT=@IDHTMT;
	IF @COUNT=0
	BEGIN
		DECLARE @Date datetime = getdate();
		INSERT INTO TW_LoaiMucTieu
		(IDHTMT,IDLoaiMucTieu,TenLoaiMucTieu,ThuTu,SuDung,MoTa,TinhTrucTiep,IsDelete,CreatedDate,CreatedBy,LastUpdatedDate,LastUpdatedBy,STT)
		SELECT @IDHTMT,IDLoaiMucTieu,TenLoaiMucTieu,ThuTu,SuDung,MoTa,TinhTrucTiep,0,@Date,@IDNhanSu,@Date,@IDNhanSu,row_number() over (order by ThuTu) as STT 
		FROM ENUM_LoaiMucTieu;
	END;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_LoaiMucTieu_SapXep]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_THI_LoaiMucTieu_SapXep]
@IDHTMT	bigint = null,
@IDNhanSu bigint,
@Overwrite bit=0
AS
BEGIN
	UPDATE TW_LoaiMucTieu 
	SET STT = OtherTable.STT
	FROM (SELECT IDHTMT,IDLoaiMucTieu,row_number() over (partition by IDHTMT order by ThuTu) as STT 
			FROM TW_LoaiMucTieu 
			WHERE ISNULL(IsDelete,0)=0 AND ISNULL(SuDung,0)=1 AND IDHTMT=@IDHTMT) AS OtherTable
	WHERE TW_LoaiMucTieu.IDLoaiMucTieu=OtherTable.IDLoaiMucTieu
	AND TW_LoaiMucTieu.IDHTMT=OtherTable.IDHTMT;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_MucTieu_SapXep]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_THI_MucTieu_SapXep]
@IDHTMT	bigint = null,
@IDMucTieuChaOld bigint,
@IDMucTieuCha bigint,
@IDMucTieu bigint,
@IDNhanSu bigint,
@Overwrite bit=0
AS
BEGIN
	DECLARE @NgayTao datetime = getdate();
	DECLARE @Count int=0, @Count1 int=0, @Count2 int=0, @CapBac tinyint=0;

	SELECT @Count=Count(*) FROM TW_MucTieu WHERE IDMucTieuCha=@IDMucTieu and ISNULL(IsDelete,0)=0 AND IDHTMT=@IDHTMT;
	IF (@Count=0)
	BEGIN
		UPDATE TW_MucTieu SET CoLopCon=0 WHERE IDMucTieu=@IDMucTieu and ISNULL(IsDelete,0)=0 AND IDHTMT=@IDHTMT;
	END;

	DECLARE @TMP_ThuMuc TABLE(IDMucTieuPK	bigint not null,
							  CoLopCon	bit null,
							  CapBac	tinyint null,
							  CayThuMuc	nvarchar(256) null,
							  IDMucTieuCha	bigint null,
							  MaThuMuc	nvarchar(4000) null,
							  PRIMARY KEY (IDMucTieuPK)
							  );

	--Cập nhật trạng thái Mục Tiêu Cha cũ
	if(ISNULL(@IDMucTieuChaOld,0)>0)
	BEGIN
		SELECT @Count=Count(*) FROM TW_MucTieu WHERE IDMucTieuCha=@IDMucTieuChaOld and ISNULL(IsDelete,0)=0 AND IDHTMT=@IDHTMT;
		IF (@Count>0)
			UPDATE TW_MucTieu SET CoLopCon=1 WHERE IDMucTieu=@IDMucTieuChaOld and ISNULL(IsDelete,0)=0 AND IDHTMT=@IDHTMT;
		ELSE
			UPDATE TW_MucTieu SET CoLopCon=0 WHERE IDMucTieu=@IDMucTieuChaOld and ISNULL(IsDelete,0)=0 AND IDHTMT=@IDHTMT;
	END;

	----Cập nhật trạng thái Mục Tiêu Cha mới
	UPDATE TW_MucTieu SET CoLopCon=1 WHERE IDMucTieu=@IDMucTieuCha and IDHTMT=@IDHTMT;
	----Cập nhật CayThuMuc nếu null
	UPDATE TW_MucTieu SET CayThuMuc=';'+cast(IDMucTieu as varchar(20))+';',MaThuMuc=';'+cast(MaMucTieu as varchar(50))+';' WHERE IDMucTieu=@IDMucTieuCha AND IDHTMT=@IDHTMT and MaThuMuc is null ;
	
	--Lớp 1 Thêm bản thân mục tiêu vào bảng tạm
	IF ISNULL(@IDMucTieuCha,0)=0
		BEGIN
			INSERT INTO @TMP_ThuMuc (IDMucTieuPK,IDMucTieuCha,CoLopCon,CapBac,CayThuMuc,MaThuMuc)
			SELECT mt.IDMucTieu,mt.IDMucTieuCha,0,1,';'+cast(mt.IDMucTieu as varchar(20))+';',';'+mt.MaMucTieu+';'
			FROM TW_MucTieu mt
			WHERE mt.IDHTMT=@IDHTMT AND ISNULL(mt.IsDelete,0)=0 AND mt.IDMucTieu = @IDMucTieu;
		END;
	ELSE
		BEGIN
			INSERT INTO @TMP_ThuMuc (IDMucTieuPK,IDMucTieuCha,CoLopCon,CapBac,CayThuMuc,MaThuMuc)
			SELECT mt.IDMucTieu,mt.IDMucTieuCha,0,ISNULL(tmp.CapBac,0)+1,ISNULL(tmp.CayThuMuc,';')+cast(mt.IDMucTieu as varchar(20))+';',ISNULL(tmp.MaThuMuc,';')+mt.MaMucTieu+';'
			FROM TW_MucTieu mt
			INNER JOIN TW_MucTieu tmp on mt.IDHTMT=tmp.IDHTMT AND tmp.IDMucTieu=mt.IDMucTieuCha
			WHERE mt.IDHTMT=@IDHTMT AND ISNULL(mt.IsDelete,0)=0 AND mt.IDMucTieu=@IDMucTieu;
		END;

	SELECT @Count2=COUNT(*),@CapBac=MAX(CapBac) FROM @TMP_ThuMuc;
	SET @Count1=@Count2;
	
	IF @CapBac>20 GOTO CapNhatMucTieu;

	--Lớp 2 + n = Thêm n lớp con
	DECLARE @i int = 2
	DECLARE @MaxLevel int = 20;
	WHILE @i < @MaxLevel
	BEGIN
		SET @i = @i + 1

		SELECT @Count2=COUNT(*)
		FROM TW_MucTieu mt
		INNER JOIN @TMP_ThuMuc tmp on mt.IDHTMT=@IDHTMT AND tmp.IDMucTieuPK=mt.IDMucTieuCha and tmp.CapBac=@CapBac
		WHERE mt.IDHTMT=@IDHTMT AND ISNULL(mt.IsDelete,0)=0 AND ISNULL(mt.IDMucTieuCha,0) = tmp.IDMucTieuPK;

		if @Count2=0
		BEGIN
			SET @i=@MaxLevel+2;
			GOTO CapNhatMucTieu;
		END;

		INSERT INTO @TMP_ThuMuc (IDMucTieuPK,IDMucTieuCha,CoLopCon,CapBac,CayThuMuc,MaThuMuc)
		SELECT mt.IDMucTieu,mt.IDMucTieuCha,0,ISNULL(tmp.CapBac,0)+1,ISNULL(tmp.CayThuMuc,';')+cast(mt.IDMucTieu as varchar(20))+';',ISNULL(tmp.MaThuMuc,';')+mt.MaMucTieu+';'
		FROM TW_MucTieu mt
		INNER JOIN @TMP_ThuMuc tmp on mt.IDHTMT=@IDHTMT AND tmp.IDMucTieuPK=mt.IDMucTieuCha and tmp.CapBac=@CapBac
		WHERE mt.IDHTMT=@IDHTMT AND ISNULL(mt.IsDelete,0)=0 AND ISNULL(mt.IDMucTieuCha,0) = tmp.IDMucTieuPK;

		SELECT @CapBac=@CapBac+1;
		IF @CapBac>@MaxLevel
		BEGIN
			SET @i=@MaxLevel+2;
			GOTO CapNhatMucTieu;
		END;
		SET @Count1=@Count2;
	END
	
	CapNhatMucTieu: 
		UPDATE @TMP_ThuMuc 
		SET CoLopCon=1
		FROM (SELECT DISTINCT IDMucTieuCha
			  FROM @TMP_ThuMuc) AS OtherTable
		WHERE IDMucTieuPK=OtherTable.IDMucTieuCha

		UPDATE TW_MucTieu 
		SET CoLopCon = OtherTable.CoLopCon, 
		    CapBac = OtherTable.CapBac, 
			CayThuMuc = UPPER(OtherTable.CayThuMuc),
			MaThuMuc = UPPER(OtherTable.MaThuMuc)
		FROM (SELECT IDMucTieuPK,CoLopCon,CapBac,CayThuMuc,MaThuMuc FROM @TMP_ThuMuc) AS OtherTable
		WHERE TW_MucTieu.IDMucTieu=OtherTable.IDMucTieuPK
		AND TW_MucTieu.IDHTMT=@IDHTMT;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_MucTieu_SapXep_HTMT]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_THI_MucTieu_SapXep_HTMT]
@IDHTMT	bigint = null,
@IDNhanSu bigint=1,
@Overwrite bit=0
AS
BEGIN
	UPDATE TW_MucTieu 
	SET CapBac=1
	WHERE IDHTMT=@IDHTMT
	AND ISNULL(IDMucTieuCha,0)=0
	AND ISNULL(CapBac,0)!=1;

	UPDATE TW_MucTieu 
	SET CayThuMuc=';'+cast(IDMucTieu as varchar(20))+';'
	WHERE IDHTMT=@IDHTMT
	AND ISNULL(IDMucTieuCha,0)=0
	AND CayThuMuc is null;

	DECLARE @TMP_MucTieu TABLE( IDMucTieu bigint NOT NULL,
								IDMucTieuCha bigint,
								IDHTMT	bigint,
								STT int
								PRIMARY KEY (IDMucTieu)
							  );
	DECLARE @iCapBac int = 0;
	WHILE @iCapBac <= 20
	BEGIN
		SET @iCapBac = @iCapBac + 1
		
		DELETE FROM @TMP_MucTieu;
		
		INSERT INTO @TMP_MucTieu (IDMucTieu,IDMucTieuCha,IDHTMT,STT)
		SELECT TOP 100000 IDMucTieu,IDMucTieuCha,IDHTMT,ROW_NUMBER() OVER(ORDER BY IDMucTieu ASC) as STT 
		FROM TW_MucTieu 
		WHERE IDHTMT=@IDHTMT
		AND ISNULL(IsDelete,0)=0 
		AND ISNULL(CapBac,1)=@iCapBac 
		AND MaMucTieu is not null
		AND (MaThuMuc is null or CayThuMuc is null);

		DECLARE @MaxCount int;
		SELECT @MaxCount=COUNT(*) FROM @TMP_MucTieu;
		IF @MaxCount>0
		BEGIN
			DECLARE @IDMucTieu bigint;
			DECLARE @IDMucTieuCha bigint;
			DECLARE @i int = 0;
			WHILE @i <= @MaxCount
			BEGIN
				SET @i = @i + 1
				SELECT @IDMucTieu=IDMucTieu,@IDMucTieuCha=IDMucTieuCha FROM @TMP_MucTieu WHERE STT=@i;
				EXEC sp_THI_MucTieu_SapXep @IDHTMT,@IDMucTieuCha,@IDMucTieuCha,@IDMucTieu,@IDNhanSu,@Overwrite;
			END
		END;

	END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_MucTieu_SapXep_null]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_THI_MucTieu_SapXep_null]

AS
BEGIN
	UPDATE TW_MucTieu 
	SET CapBac=1
	WHERE ISNULL(IDMucTieuCha,0)=0
	AND ISNULL(CapBac,0)!=1;

	UPDATE TW_MucTieu 
	SET CayThuMuc=';'+cast(IDMucTieu as varchar(20))+';'
	WHERE ISNULL(IDMucTieuCha,0)=0
	AND CayThuMuc is null;

	DECLARE @TMP_MucTieu TABLE( IDMucTieu bigint NOT NULL,
								IDMucTieuCha bigint,
								IDHTMT	bigint,
								STT int
								PRIMARY KEY (IDMucTieu)
							  );
	DECLARE @iCapBac int = 0;
	WHILE @iCapBac <= 20
	BEGIN
		SET @iCapBac = @iCapBac + 1
		
		DELETE FROM @TMP_MucTieu;
		
		INSERT INTO @TMP_MucTieu (IDMucTieu,IDMucTieuCha,IDHTMT,STT)
		select TOP 100000 IDMucTieu,IDMucTieuCha,IDHTMT,ROW_NUMBER() OVER(ORDER BY IDMucTieu ASC) as STT from TW_MucTieu 
		where ISNULL(IsDelete,0)=0 
		and CapBac=@iCapBac 
		AND MaMucTieu is not null
		and (MaThuMuc is null or CayThuMuc is null);

		DECLARE @MaxCount int;
		SELECT @MaxCount=COUNT(*) FROM @TMP_MucTieu;
		IF @MaxCount>0
		BEGIN
			DECLARE
			@IDHTMT	bigint = null,
			@IDMucTieuChaOld bigint,
			@IDMucTieuCha bigint,
			@IDMucTieu bigint,
			@IDNhanSu bigint=1,
			@Overwrite bit=1;

			DECLARE @i int = 0;
			WHILE @i <= @MaxCount
			BEGIN
				SET @i = @i + 1
				SELECT @IDHTMT=IDHTMT, @IDMucTieu=IDMucTieu, @IDMucTieuCha=IDMucTieuCha FROM @TMP_MucTieu WHERE STT=@i;
				EXEC sp_THI_MucTieu_SapXep @IDHTMT,@IDMucTieuChaOld,@IDMucTieuCha,@IDMucTieu,@IDNhanSu,@Overwrite;
			END
		END;
	END

	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_MucTieuCon_SapXep]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_THI_MucTieuCon_SapXep]
@IDHTMT	bigint = null,
@IDMucTieu bigint,
@IDNhanSu bigint,
@Overwrite bit=0
AS
BEGIN
	DECLARE @CapBac int;
	DECLARE @CayThuMuc nvarchar(256);

	----Cập nhật trạng thái Mục Tiêu Cha
	UPDATE TW_MucTieu SET CoLopCon=1 WHERE IDMucTieu=@IDMucTieu and IDHTMT=@IDHTMT;
	----Cập nhật CayThuMuc nếu null
	UPDATE TW_MucTieu SET CayThuMuc=';'+cast(IDMucTieu as varchar(20))+';' WHERE IDMucTieu=@IDMucTieu AND IDHTMT=@IDHTMT and CayThuMuc is null ;
	
	SELECT @CapBac=CapBac, @CayThuMuc=CayThuMuc FROM TW_MucTieu WHERE IDMucTieu=@IDMucTieu and IDHTMT=@IDHTMT;

	UPDATE TW_MucTieu SET CapBac=@CapBac+1,CayThuMuc=@CayThuMuc+cast(IDMucTieu as varchar(20))+';'
	WHERE IDMucTieuCha=@IDMucTieu and IDHTMT=@IDHTMT and ISNULL(IsDelete,0)=0;
	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_NhomMucTieu_SapXep]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_THI_NhomMucTieu_SapXep]
@IDNhomMucTieu bigint,
@IDChaOld bigint,
@IDCha bigint,
@IDNhanSu bigint,
@IDKhachHang int
AS
BEGIN
	DELETE FROM TMP_NhomMucTieuThuMuc WHERE IDNhanSuLoad=@IDNhanSu;

	DECLARE @NgayTao datetime = getdate();
	DECLARE @Count int=0, @Count1 int=0, @Count2 int=0, @CapBac tinyint=0;
	DECLARE @ThuTuCha bigint=0;

	SELECT @Count=Count(*) FROM TMP_NhomMucTieuThuMuc WHERE IDCha=@IDNhomMucTieu;
	IF (@Count=0)
	BEGIN
		UPDATE TMP_NhomMucTieuThuMuc SET CoLopCon=0 WHERE IDNhomMucTieu=@IDNhomMucTieu;
	END;

	--Cập nhật trạng thái Mục Tiêu Cha cũ
	if(@IDChaOld is not null)
	BEGIN
		SELECT @Count=Count(*) FROM TW_NhomMucTieu WHERE IDCha=@IDChaOld and ISNULL(IsDelete,0)=0;
		IF (@Count>0)
			UPDATE TW_NhomMucTieu SET CoLopCon=1 WHERE IDNhomMucTieu=@IDChaOld and ISNULL(IsDelete,0)=0;
		ELSE
			UPDATE TW_NhomMucTieu SET CoLopCon=0 WHERE IDNhomMucTieu=@IDChaOld and ISNULL(IsDelete,0)=0;
	END;

	----Cập nhật trạng thái Mục Tiêu Cha mới
	UPDATE TW_NhomMucTieu SET CoLopCon=1 WHERE IDNhomMucTieu=@IDCha and ISNULL(IsDelete,0)=0;
	----Cập nhật CayThuMuc nếu null
	UPDATE TW_NhomMucTieu SET CayThuMuc=';'+cast(IDNhomMucTieu as varchar(20))+';' WHERE IDNhomMucTieu=@IDCha AND CayThuMuc is null ;

	--Lớp 1 Thêm bản thân cơ cấu vào bảng tạm
	IF ISNULL(@IDCha,0)=0
		BEGIN
			INSERT INTO TMP_NhomMucTieuThuMuc (IDNhomMucTieu,IDNhanSuLoad,NgayTao,IDCha,IDKhachHang,CoLopCon,CapBac,ThuTu,ThuTuCha,CayThuMuc)
			SELECT nmt.IDNhomMucTieu,@IDNhanSu,@NgayTao,nmt.IDCha,@IDKhachHang,0,1,ThuTu,ThuTu,';'+cast(nmt.IDNhomMucTieu as varchar(20))+';'
			FROM TW_NhomMucTieu nmt
			WHERE ISNULL(nmt.IsDelete,0)=0 AND nmt.IDNhomMucTieu = @IDNhomMucTieu;
		END;
	ELSE
		BEGIN
			INSERT INTO TMP_NhomMucTieuThuMuc (IDNhomMucTieu,IDNhanSuLoad,NgayTao,IDCha,IDKhachHang,CoLopCon,CapBac,ThuTu,ThuTuCha,CayThuMuc)
			SELECT nmt.IDNhomMucTieu,@IDNhanSu,@NgayTao,nmt.IDCha,@IDKhachHang,0,ISNULL(tmp.CapBac,0)+1,tmp.ThuTu,tmp.ThuTuCha,ISNULL(tmp.CayThuMuc,';')+cast(nmt.IDNhomMucTieu as varchar(20))+';'
			FROM TW_NhomMucTieu nmt
			INNER JOIN TW_NhomMucTieu tmp on tmp.IDNhomMucTieu=nmt.IDCha
			WHERE ISNULL(nmt.IsDelete,0)=0 AND nmt.IDNhomMucTieu=@IDNhomMucTieu;
		END;

	SELECT @Count2=COUNT(*),@CapBac=MAX(CapBac) FROM TMP_NhomMucTieuThuMuc WHERE IDKhachHang=@IDKhachHang AND IDNhanSuLoad=@IDNhanSu AND NgayTao=@NgayTao;
	SET @Count1=@Count2;
	
	IF @CapBac>9 GOTO CapNhatNhomMucTieu;

	--Lớp 2 + n = Thêm n lớp con
	DECLARE @i int = 2
	DECLARE @MaxLevel int = 20;
	WHILE @i < @MaxLevel
	BEGIN
		SET @i = @i + 1
		INSERT INTO TMP_NhomMucTieuThuMuc (IDNhomMucTieu,IDNhanSuLoad,NgayTao,IDCha,IDKhachHang,CoLopCon,CapBac,ThuTu,ThuTuCha,CayThuMuc)
		SELECT nmt.IDNhomMucTieu,@IDNhanSu,@NgayTao,nmt.IDCha,@IDKhachHang,nmt.CoLopCon,ISNULL(tmp.CapBac,0)+1,tmp.ThuTu,tmp.ThuTuCha,ISNULL(tmp.CayThuMuc,';')+cast(nmt.IDNhomMucTieu as varchar(20))+';'
		FROM TW_NhomMucTieu nmt
		INNER JOIN TMP_NhomMucTieuThuMuc tmp on tmp.IDNhanSuLoad=@IDNhanSu AND tmp.NgayTao=@NgayTao AND tmp.IDNhomMucTieu=nmt.IDCha and tmp.CapBac=@CapBac
		WHERE ISNULL(nmt.IsDelete,0)=0 AND ISNULL(nmt.IDCha,0) = tmp.IDNhomMucTieu;

		SELECT @Count2=COUNT(*), @CapBac=@CapBac+1 FROM TMP_NhomMucTieuThuMuc WHERE IDkhachHang=@IDkhachHang AND IDNhanSuLoad=@IDNhanSu AND NgayTao=@NgayTao;
		IF @Count2=@Count1 OR @CapBac>@MaxLevel OR @Count2=0
		BEGIN
			SET @i=@MaxLevel+2;
			GOTO CapNhatNhomMucTieu;
		END;
		SET @Count1=@Count2;
	END

	CapNhatNhomMucTieu: 
		UPDATE TMP_NhomMucTieuThuMuc 
		SET CoLopCon=1
		FROM (SELECT DISTINCT IDKhachHang, IDCha
			FROM TMP_NhomMucTieuThuMuc) AS OtherTable
		WHERE TMP_NhomMucTieuThuMuc.IDNhomMucTieu=OtherTable.IDCha
		AND TMP_NhomMucTieuThuMuc.IDKhachHang=OtherTable.IDKhachHang;

		UPDATE TW_NhomMucTieu 
		SET CoLopCon = OtherTable.CoLopCon, 
		    CapBac = OtherTable.CapBac, 
			ThuTuCha = OtherTable.ThuTuCha,
			CayThuMuc = UPPER(OtherTable.CayThuMuc) 
		FROM (SELECT * 
			FROM TMP_NhomMucTieuThuMuc WHERE IDNhanSuLoad=@IDNhanSu) AS OtherTable
		WHERE TW_NhomMucTieu.IDNhomMucTieu=OtherTable.IDNhomMucTieu;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_TaoCanhBao]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_THI_TaoCanhBao]
@IDKhachHang int
AS
BEGIN
	DECLARE @DateFrom datetime= '2000-01-01';
	DECLARE @DateTo datetime = getdate();
	DECLARE @DateOld datetime = @DateTo-30;
	DECLARE @Count int;

	SELECT @Count=Count(*) FROM SYS_CanhBao WHERE IDKhachHang=@IDKhachHang;
	IF @Count=0
	BEGIN
		INSERT INTO SYS_CanhBao (IDKhachHang,LastUpdatedDate)
		VALUES (@IDKhachHang,@DateTo);
	END;
	ELSE
	BEGIN
		SELECT @DateFrom=LastUpdatedDate FROM SYS_CanhBao WHERE IDKhachHang=@IDKhachHang;

		UPDATE SYS_CanhBao
		SET LastUpdatedDate=@DateTo
		WHERE IDKhachHang=@IDKhachHang;
	END;
	
	--Xóa dữ liệu cũ
	DELETE FROM TW_CanhBao WHERE CreatedDate<=@DateOld;

	--Duyệt cấp 1
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,mt.IDHTTS,0,mt.IDNguoiPhuTrach,@DateTo,1,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and NgayDuyet1 between @DateFrom and @DateTo
	and mt.IDTrangThaiDuyet=4--Đã duyệt cấp 1
	GROUP BY mt.IDHTMT,mt.IDHTTS,mt.IDNguoiPhuTrach;

	--Duyệt cấp 2
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,mt.IDHTTS,0,mt.IDNguoiPhuTrach,@DateTo,2,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and NgayDuyet2 between @DateFrom and @DateTo
	and mt.IDTrangThaiDuyet=7--Đã duyệt cấp 2
	GROUP BY mt.IDHTMT,mt.IDHTTS,mt.IDNguoiPhuTrach

	--Duyệt cấp 3
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,mt.IDHTTS,0,mt.IDNguoiPhuTrach,@DateTo,3,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and NgayDuyet3 between @DateFrom and @DateTo
	and mt.IDTrangThaiDuyet=10--Đã duyệt cấp 3
	GROUP BY mt.IDHTMT,mt.IDHTTS,mt.IDNguoiPhuTrach

	--Hủy Duyệt cấp 1
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,mt.IDHTTS,0,mt.IDNguoiPhuTrach,@DateTo,4,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and NgayHuyDuyet1 between @DateFrom and @DateTo
	GROUP BY mt.IDHTMT,mt.IDHTTS,mt.IDNguoiPhuTrach

	--Hủy Duyệt cấp 2
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,mt.IDHTTS,0,mt.IDNguoiPhuTrach,@DateTo,5,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and NgayHuyDuyet2 between @DateFrom and @DateTo
	GROUP BY mt.IDHTMT,mt.IDHTTS,mt.IDNguoiPhuTrach

	--Hủy Duyệt cấp 3
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,mt.IDHTTS,0,mt.IDNguoiPhuTrach,@DateTo,6,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and NgayHuyDuyet3 between @DateFrom and @DateTo
	GROUP BY mt.IDHTMT,mt.IDHTTS,mt.IDNguoiPhuTrach

	--Đánh giá bộ phận
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT DG.IDHTMT,DG.IDHTTS,DG.IDDanhGia,DG.IDNguoiPhuTrach,@DateTo,10,null,0
	FROM TW_DanhGia DG
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=DG.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and DG.IDCoCau>0
	and DG.CreatedDate between @DateFrom and @DateTo

	--Sửa Đánh giá bộ phận
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT DG.IDHTMT,DG.IDHTTS,DG.IDDanhGia,DG.IDNguoiPhuTrach,@DateTo,11,null,0
	FROM TW_DanhGia DG
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=DG.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and DG.IDCoCau>0
	and DG.LastUpdatedDate between @DateFrom and @DateTo

	--Đánh giá cá nhân
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT DG.IDHTMT,DG.IDHTTS,DG.IDDanhGia,DG.IDNguoiPhuTrach,@DateTo,12,null,0
	FROM TW_DanhGia DG
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=DG.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and DG.IDNguoiPhuTrach>0
	and DG.CreatedDate between @DateFrom and @DateTo

	--Sửa Đánh giá cá nhân
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT DG.IDHTMT,DG.IDHTTS,DG.IDDanhGia,DG.IDNguoiPhuTrach,@DateTo,13,null,0
	FROM TW_DanhGia DG
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=DG.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and DG.IDNguoiPhuTrach>0
	and DG.LastUpdatedDate between @DateFrom and @DateTo

	--Cảnh báo
	DECLARE @KyHan tinyint;
	SELECT @KyHan=KyHan FROM SYS_CanhBao WHERE IDKhachHang=IDKhachHang;
	IF @KyHan=null
	BEGIN
		SELECT @KyHan=3;
	END;

	--Chỉ tiêu sắp đến hạn
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,0,0,mt.IDNguoiPhuTrach,@DateTo,14,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and mt.IDTrangThaiDuyet in (4,7,10)
	AND ISNULL(mt.IDTrangThaiMucTieu,1) in (1,2)
	AND mt.KyHan>=@DateTo-@KyHan
	GROUP BY mt.IDHTMT,mt.IDNguoiPhuTrach;

	--Task sắp đến hạn
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,0,0,mt.IDNguoiPhuTrach,@DateTo,15,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	INNER JOIN TW_MucTieuTask mtt on mtt.IDMucTieu=mt.IDMucTieu
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and mt.IDTrangThaiDuyet in (4,7,10)
	AND ISNULL(mt.IDTrangThaiMucTieu,1) in (1,2)
	AND ISNULL(mtt.HoanThanh,0)=0
	AND mtt.KyHan>=@DateTo-@KyHan
	GROUP BY mt.IDHTMT,mt.IDNguoiPhuTrach;

	--Chỉ tiêu hết hạn
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,0,0,mt.IDNguoiPhuTrach,@DateTo,16,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and mt.IDTrangThaiDuyet in (4,7,10)
	AND ISNULL(mt.IDTrangThaiMucTieu,1) in (1,2)
	AND mt.KyHan>@DateTo
	GROUP BY mt.IDHTMT,mt.IDNguoiPhuTrach;

	--Task sắp hết hạn
	INSERT INTO TW_CanhBao (IDHTMT,IDHTTS,IDDanhGia,IDNguoiPhuTrach,CreatedDate,IDLoaiCanhBao,SoLuong,IsXem)
	SELECT mt.IDHTMT,0,0,mt.IDNguoiPhuTrach,@DateTo,17,COUNT(*) as SoLuong,0
	FROM TW_MucTieu mt
	INNER JOIN TW_HeThongMucTieu HTMT on HTMT.IDHTMT=mt.IDHTMT
	INNER JOIN TW_MucTieuTask mtt on mtt.IDMucTieu=mt.IDMucTieu
	WHERE HTMT.IDKhachHang=@IDKhachHang
	and ISNULL(mt.IsDelete,0)=0
	AND mt.IDNguoiPhuTrach is not null
	and mt.IDTrangThaiDuyet in (4,7,10)
	AND ISNULL(mt.IDTrangThaiMucTieu,1) in (1,2)
	AND ISNULL(mtt.HoanThanh,0)=0
	AND mtt.KyHan>@DateTo
	GROUP BY mt.IDHTMT,mt.IDNguoiPhuTrach;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_TinhTrongSoPT]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_THI_TinhTrongSoPT]
@IDHTMT	bigint = null,
@IDHTTS bigint,
@IDCoCau bigint,
@IDNguoiPhuTrach bigint,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	DECLARE @IDDanhGia bigint=0;
	DECLARE @COUNT int=0;
	DECLARE @Date datetime = getdate();

	SELECT @COUNT=COUNT(*) FROM TW_DanhGia WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0);
	IF @COUNT=0 
	BEGIN
		INSERT INTO TW_DanhGia
		(IDHTMT,IDHTTS,IDCoCau,IDNguoiPhuTrach,CreatedDate,CreatedBy,LastUpdatedDate,LastUpdatedBy)
		VALUES (@IDHTMT,@IDHTTS,ISNULL(@IDCoCau,0),ISNULL(@IDNguoiPhuTrach,0),@Date,@IDNhanSu,@Date,@IDNhanSu);
		
		SELECT @IDDanhGia=SCOPE_IDENTITY();
	END;
	ELSE
	BEGIN
		SELECT @IDDanhGia=IDDanhGia 
		FROM TW_DanhGia
		WHERE IDHTMT=@IDHTMT AND IDHTTS=@IDHTTS AND IDCoCau=ISNULL(@IDCoCau,0) AND IDNguoiPhuTrach=ISNULL(@IDNguoiPhuTrach,0);
	END;

	--Xóa trọng số % loại mục tiêu
	DELETE FROM TW_NhomMucTieuTrongSo WHERE IDDanhGia=@IDDanhGia;

	DECLARE @TMP_TrongSoPhanTram TABLE(IDHTMT bigint NOT NULL,
										IDMucTieu bigint NOT NULL,
										IDCoCau bigint NOT NULL,
										IDNguoiPhuTrach bigint NOT NULL,
										TrongSo decimal(5, 2) NULL,
										IDLoaiMucTieu tinyint NOT NULL,
										IDNhomMucTieu bigint NOT NULL,
										IDNhomMucTieuCha bigint NOT NULL,
										IDNhomMucTieuGoc bigint NOT NULL,
										TinhTrucTiep bit NULL,
										TrongSoLoaiMucTieu decimal(9, 5) NULL,
										TrongSoPT decimal(9, 5) NULL,
										PRIMARY KEY (IDHTMT, IDMucTieu, IDCoCau, IDNguoiPhuTrach)
									  );
	DECLARE @TMP_TongTrongSoTrucTiep TABLE(IDNhom tinyint NOT NULL,
										   TongNhom decimal(13, 2) NULL,
										   PRIMARY KEY (IDNhom)
										  );

	DECLARE @TongTrongSo decimal(18,5);
	DECLARE @ChuThe bit=0;--Bộ phận

	IF ISNULL(@IDCoCau,0)<>0
	BEGIN
		SET @IDNguoiPhuTrach=0;
	END;

	--@ChuThe: 0-Tổ chức, 1-Cá nhân
	SELECT @ChuThe=0;
	IF @IDCoCau=0 OR (@IDCoCau IS NULL AND ISNULL(@IDNguoiPhuTrach,0)>0)
	BEGIN
		SELECT @ChuThe=1;
	END;
	
	--Tao ban ghi TrongSo
	INSERT INTO TW_MucTieuTrongSo
		   (IDHTMT,IDHTTS,IDMucTieu,IDCoCau,IDNguoiPhuTrach,DaDuyet,LastUpdatedDate,LastUpdatedBy)
	SELECT mt.IDHTMT,@IDHTTS,mt.IDMucTieu,
				CASE 
					WHEN @ChuThe=1 THEN 0--Cá nhân
					ELSE mt.IDCoCau
				END AS IDCoCau,
			ISNULL(@IDNguoiPhuTrach,0),DaDuyet,getdate(),@IDNhanSu
	FROM TW_MucTieu mt
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDHTMT=@IDHTMT AND lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu --and ISNULL(lmt.TinhTrucTiep,0)=0
	LEFT JOIN TW_MucTieuTrongSo mtts on mtts.IDHTMT=mt.IDHTMT and mtts.IDHTTS=mt.IDHTTS and mtts.IDMucTieu=mt.IDMucTieu 
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0))
			)
	WHERE mt.IDHTMT=@IDHTMT
	  AND isnull(mt.IsDelete,0) = 0
	  AND mtts.IDMucTieu is null
	  AND mt.IDHTTS=@IDHTTS
	  AND (
			(ISNULL(@ChuThe,0) = 0 AND ISNULL(mt.IDCoCau,0)>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1  AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
		
	INSERT INTO @TMP_TrongSoPhanTram
	(IDHTMT,IDMucTieu,IDCoCau,IDNguoiPhuTrach,TrongSo,IDLoaiMucTieu,IDNhomMucTieu,IDNhomMucTieuCha,IDNhomMucTieuGoc,TrongSoLoaiMucTieu,TinhTrucTiep,TrongSoPT)
	SELECT mtts.IDHTMT,mtts.IDMucTieu,mtts.IDCoCau,mtts.IDNguoiPhuTrach,mt.TrongSo,lmt.IDLoaiMucTieu,mt.IDNhomMucTieu,nmt.IDCha,
			CASE WHEN nmt.IDCha=0 then nmt.IDNhomMucTieu ELSE nmt.IDCha END as IDNhomMucTieuGoc,
			ISNULL(lmt.TrongSo,0),ISNULL(lmt.TinhTrucTiep,0),0
	FROM TW_MucTieuTrongSo mtts
	INNER JOIN TW_MucTieu mt on mt.IDMucTieu=mtts.IDMucTieu and mt.IDHTMT=mtts.IDHTMT
		and (
				(ISNULL(@ChuThe,0) = 0 AND mtts.IDCoCau>0 AND mtts.IDNguoiPhuTrach=0 AND ISNULL(mtts.IDCoCau,0)=ISNULL(mt.IDCoCau,0))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND ISNULL(mtts.IDNguoiPhuTrach,0)=ISNULL(mt.IDNguoiPhuTrach,0))
			)
	INNER JOIN TW_NhomMucTieu nmt on nmt.IDNhomMucTieu=mt.IDNhomMucTieu
	INNER JOIN TW_LoaiMucTieu lmt on lmt.IDHTMT=@IDHTMT AND lmt.IDLoaiMucTieu=nmt.IDLoaiMucTieu-- and ISNULL(lmt.TinhTrucTiep,0)=0
	WHERE mtts.IDHTMT=@IDHTMT
	  AND isnull(mt.IsDelete,0) = 0
	  AND ISNULL(mt.IDTrangThaiDuyet,0) in (4,7,10)--Đã duyệt 1/2/3
	  AND mtts.IDHTTS=@IDHTTS
	  AND mt.IDHTTS = @IDHTTS
	  AND (
			(ISNULL(@ChuThe,0) = 0 AND mt.IDCoCau>0 AND (@IDCoCau Is NULL OR ISNULL(mt.IDCoCau,0)=@IDCoCau))
			OR 
			(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(mt.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
		)
	
	--Tính TongTrongSo chỉ tiêu chung
	INSERT INTO @TMP_TongTrongSoTrucTiep(IDNhom,TongNhom)
	SELECT 0, SUM(TrongSo)
	FROM @TMP_TrongSoPhanTram
	WHERE TinhTrucTiep=0;

	--Tính TongTrongSo chỉ tiêu cộng trừ trực tiếp
	INSERT INTO @TMP_TongTrongSoTrucTiep(IDNhom,TongNhom)
	SELECT IDLoaiMucTieu, SUM(TrongSo)
	FROM @TMP_TrongSoPhanTram
	WHERE TinhTrucTiep=1
	GROUP BY IDLoaiMucTieu;

	--Tính TrongSoPT chỉ tiêu chung
	UPDATE @TMP_TrongSoPhanTram 
	SET TrongSoPT=TrongSo*100/OtherTable.TongNhom
	FROM (SELECT * FROM @TMP_TongTrongSoTrucTiep WHERE IDNhom=0 AND TongNhom!=0) AS OtherTable
	WHERE TinhTrucTiep=0;
	
	--Tính TrongSoPT chỉ tiêu cộng trừ trực tiếp
	UPDATE @TMP_TrongSoPhanTram 
	SET TrongSoPT=TrongSo*TrongSoLoaiMucTieu/OtherTable.TongNhom
	FROM (SELECT * FROM @TMP_TongTrongSoTrucTiep WHERE IDNhom>0 AND TongNhom!=0) AS OtherTable
	WHERE TinhTrucTiep=1
	AND IDLoaiMucTieu=OtherTable.IDNhom;

	--Cập nhật TrongSoPT
	UPDATE TW_MucTieuTrongSo
		SET TrongSoPT=OtherTable.TrongSoPT
		FROM (SELECT ts.* FROM @TMP_TrongSoPhanTram TS
			  WHERE ts.IDHTMT=@IDHTMT) AS OtherTable
		WHERE TW_MucTieuTrongSo.IDHTMT=OtherTable.IDHTMT
		  AND TW_MucTieuTrongSo.IDHTTS=@IDHTTS
		  AND TW_MucTieuTrongSo.IDMucTieu=OtherTable.IDMucTieu
		  AND (
				(ISNULL(@ChuThe,0) = 0 AND TW_MucTieuTrongSo.IDCoCau>0 AND TW_MucTieuTrongSo.IDNguoiPhuTrach=0 AND (@IDCoCau Is NULL OR ISNULL(TW_MucTieuTrongSo.IDCoCau,0)=@IDCoCau))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(TW_MucTieuTrongSo.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
			  );
	
	--Xoa trong so % chỉ tieu chua duyet
	UPDATE TW_MucTieuTrongSo
		SET TrongSoPT=null
		WHERE IDHTMT=@IDHTMT
		  AND IDHTTS=@IDHTTS
		  AND IDMucTieu not in (SELECT IDMucTieu FROM @TMP_TrongSoPhanTram ts WHERE ts.IDHTMT=@IDHTMT)
		  AND (
				(ISNULL(@ChuThe,0) = 0 AND TW_MucTieuTrongSo.IDCoCau>0 AND TW_MucTieuTrongSo.IDNguoiPhuTrach=0 AND (@IDCoCau Is NULL OR ISNULL(TW_MucTieuTrongSo.IDCoCau,0)=@IDCoCau))
				OR 
				(ISNULL(@ChuThe,0) = 1 AND (@IDNguoiPhuTrach Is null OR ISNULL(TW_MucTieuTrongSo.IDNguoiPhuTrach,0)=@IDNguoiPhuTrach))
			  );
	--Them trong số % loại mục tiêu con
	INSERT INTO TW_NhomMucTieuTrongSo(IDDanhGia,IDNhomMucTieu,TrongSoPT)
	select @IDDanhGia,IDNhomMucTieu,SUM(TrongSoPT) from @TMP_TrongSoPhanTram
	WHERE IDNhomMucTieuCha>0
	GROUP BY IDNhomMucTieu;

	--Them trong số % loại mục tiêu gốc
	INSERT INTO TW_NhomMucTieuTrongSo(IDDanhGia,IDNhomMucTieu,TrongSoPT)
	select @IDDanhGia,IDNhomMucTieuGoc,SUM(TrongSoPT) from @TMP_TrongSoPhanTram
	GROUP BY IDNhomMucTieuGoc;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_THI_XemCanhBao]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_THI_XemCanhBao]
@IDHTMT	bigint,
@IDHTTS	bigint,
@IDDanhGia bigint,
@IDNguoiPhuTrach bigint,
@sCreatedDate nvarchar(50),
@IDLoaiCanhBao tinyint
AS
BEGIN
	UPDATE TW_CanhBao Set IsXem=1
	WHERE IDHTMT=@IDHTMT
	AND IDHTTS=@IDHTTS
	AND IDDanhGia=@IDDanhGia
	AND IDNguoiPhuTrach=@IDNguoiPhuTrach
	AND IDLoaiCanhBao=@IDLoaiCanhBao
	AND FORMAT(CreatedDate, 'yyyy-MM-dd')=@sCreatedDate
END
GO
/****** Object:  StoredProcedure [dbo].[sp_TRA_VE_MucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_TRA_VE_MucTieu]
@IDHTMT	bigint = null,
@IDMucTieu bigint,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE TW_MucTieu
	SET IDTrangThaiDuyet=2
	WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_ChucDanh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_ChucDanh]
@IDChucDanh bigint,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE SYS_ChucDanh
	SET IsDelete=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDChucDanh=@IDChucDanh;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_CoCau]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_CoCau]
@IDCoCau bigint,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE SYS_CoCau
	SET IsDelete=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDKhachHang=@IDKhachHang and IDCoCau=@IDCoCau;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_CRM_CTL_Customer]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_CRM_CTL_Customer]
@IDHTTS bigint,
@groupBy tinyint
AS
BEGIN
	DELETE FROM CRM_CTL_Customer
	WHERE IDHTTS=@IDHTTS and groupBy=@groupBy;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_CRM_CTL_Customer_TuongTac]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_CRM_CTL_Customer_TuongTac]
@IDHTTS bigint,
@groupBy tinyint
AS
BEGIN
	DELETE FROM CRM_CTL_Customer_TuongTac
	WHERE IDHTTS=@IDHTTS and groupBy=@groupBy;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_CRM_CTL_Property]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_CRM_CTL_Property]
@IDHTMT bigint
AS
BEGIN
	DELETE FROM CRM_CTL_Property
	WHERE IDHTMT=@IDHTMT;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_CRM_CTL_Revenue]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_CRM_CTL_Revenue]
@IDHTTS bigint,
@groupBy tinyint
AS
BEGIN
	DELETE FROM CRM_CTL_Revenue
	WHERE IDHTTS=@IDHTTS and groupBy=@groupBy;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_CRM_CTL_Sale]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_CRM_CTL_Sale]
@IDHTTS bigint,
@groupBy tinyint
AS
BEGIN
	DELETE FROM CRM_CTL_Sale
	WHERE IDHTTS=@IDHTTS and groupBy=@groupBy;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_DonViTinh]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_DonViTinh]
@IDDonViTinh bigint,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE TW_DonViTinh
	SET IsDelete=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDKhachHang=@IDKhachHang and IDDonViTinh=@IDDonViTinh;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_HeThongMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_HeThongMucTieu]
@IDHTMT bigint,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE TW_HeThongMucTieu
	SET IsDelete=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDKhachHang=@IDKhachHang and IDHTMT=@IDHTMT;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_HeThongTanSuat]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_HeThongTanSuat]
@IDHTTS bigint,
@IDHTMT bigint,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE TW_HeThongTanSuat
	SET IsDelete=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDHTMT=@IDHTMT and IDHTTS=@IDHTTS;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_KhachHang]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_KhachHang]
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE SYS_KhachHang
	SET IsDeleted=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDKhachHang=@IDKhachHang;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_MucDanhGia]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_MucDanhGia]
@IDMucDanhGia bigint,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	Delete FROM TW_MucDanhGia
	WHERE IDKhachHang=@IDKhachHang and IDMucDanhGia=@IDMucDanhGia;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_MucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_MucTieu]
@IDHTMT	bigint = null,
@IDMucTieu bigint,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	--Kiểm tra trạng thái duyệt tổng hợp + duyệt nhập kết quả
	declare @iResult int=0;
	exec @iResult = sp_LAY_TrangThaiDuyet @IDMucTieu
	if @iResult!=0
	BEGIN
		RETURN @iResult;
	END;

	DECLARE @IDTrangThaiDuyet tinyint
	
	SELECT @IDTrangThaiDuyet=ISNULL(IDTrangThaiDuyet,0)
	FROM TW_MucTieu
	WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;

	IF @IDTrangThaiDuyet not in (0,1,2,5,8)
	RETURN @IDTrangThaiDuyet;

	DECLARE @Count int=0, @IDCha bigint=0;
	SELECT @IDCha=iDMucTieuCha FROM TW_MucTieu WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;

	UPDATE TW_MucTieu
	SET IsDelete=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDMucTieu;

	IF ISNULL(@IDCha,0)>0
	BEGIN
		SELECT @Count=COUNT(*) FROM TW_MucTieu WHERE IDHTMT=@IDHTMT and IDMucTieuCha=@IDCha AND ISNULL(IsDelete,0)=0;
		IF @Count=0
		BEGIN
			UPDATE TW_MucTieu SET CoLopCon=0 WHERE IDHTMT=@IDHTMT and IDMucTieu=@IDCha;
		END;
	END;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_MucTieuTask]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_MucTieuTask]
@IDTask bigint,
@IDNhanSu bigint
AS
BEGIN
	DELETE FROM TW_MucTieuTask
	WHERE IDTask=@IDTask and IDNhanSu=@IDNhanSu;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_NhanSu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_NhanSu]
@IDNhanSuGoc bigint,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE SYS_NhanSu
	SET IsDelete=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDKhachHang=@IDKhachHang and IDNhanSu=@IDNhanSuGoc;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_NhomCap]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_NhomCap]
@IDNhomCap bigint,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE TW_NhomCap
	SET IsDelete=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDKhachHang=@IDKhachHang and IDNhomCap=@IDNhomCap;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XOA_NhomMucTieu]    Script Date: 2022-10-14 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_XOA_NhomMucTieu]
@IDNhomMucTieu bigint,
@IDKhachHang int,
@IDNhanSu bigint,
@IDChucNang int
AS
BEGIN
	UPDATE TW_NhomMucTieu
	SET IsDelete=1, LastUpdatedBy=@IDNhanSu, LastUpdatedDate=getdate()
	WHERE IDNhomMucTieu=@IDNhomMucTieu;
END
GO
