CREATE DATABASE MineraHotSpringsDB;
GO

USE MineraHotSpringsDB;
GO

-- =====================================================================================
-- PHẦN 1: TẠO CẤU TRÚC BẢNG (CREATE TABLES)
-- =====================================================================================

CREATE TABLE Roles (
    RoleID INT PRIMARY KEY IDENTITY(1,1),
    RoleName NVARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE AdminUsers (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    FullName NVARCHAR(150),
    Email NVARCHAR(100) UNIQUE,
    RoleID INT CONSTRAINT FK_AdminUsers_Roles FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE NO ACTION ON UPDATE CASCADE,
    TwoFactorSecret NVARCHAR(255) NULL,
    IsActive BIT DEFAULT 1,
    LastLogin DATETIME2 NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NULL
);
GO

CREATE TABLE KhachHang (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(150) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PhoneNumber NVARCHAR(20) NULL,
    PasswordHash NVARCHAR(MAX) NULL,
    RegistrationDate DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 NULL,
    IsActive BIT DEFAULT 1
);
GO

CREATE TABLE LoaiVe (
    TicketTypeID INT PRIMARY KEY IDENTITY(1,1),
    TypeName NVARCHAR(100) NOT NULL,
    Price DECIMAL(18, 2) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0, -- Cờ Soft Delete
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL CONSTRAINT FK_LoaiVe_CreatedBy FOREIGN KEY REFERENCES AdminUsers(UserID),
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL CONSTRAINT FK_LoaiVe_UpdatedBy FOREIGN KEY REFERENCES AdminUsers(UserID)
);
GO

CREATE TABLE DichVu (
    ServiceID INT PRIMARY KEY IDENTITY(1,1),
    ServiceName NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Price DECIMAL(18, 2) NOT NULL,
    ImageUrl NVARCHAR(255) NULL,
    IsActive BIT DEFAULT 1,
    IsDeleted BIT DEFAULT 0, -- Cờ Soft Delete
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NULL CONSTRAINT FK_DichVu_CreatedBy FOREIGN KEY REFERENCES AdminUsers(UserID),
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL CONSTRAINT FK_DichVu_UpdatedBy FOREIGN KEY REFERENCES AdminUsers(UserID)
);
GO

CREATE TABLE Ve (
    TicketID BIGINT PRIMARY KEY IDENTITY(1,1),
    BookingCode NVARCHAR(20) NOT NULL UNIQUE,
    CustomerID INT NULL CONSTRAINT FK_Ve_KhachHang FOREIGN KEY (CustomerID) REFERENCES KhachHang(CustomerID) ON DELETE SET NULL ON UPDATE CASCADE,
    CustomerFullName NVARCHAR(150) NOT NULL,
    CustomerEmail NVARCHAR(100) NOT NULL,
    CustomerPhoneNumber NVARCHAR(20) NULL,
    TicketTypeID INT CONSTRAINT FK_Ve_LoaiVe FOREIGN KEY (TicketTypeID) REFERENCES LoaiVe(TicketTypeID) ON DELETE NO ACTION ON UPDATE CASCADE,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UsageDate DATE NOT NULL,
    BookingDate DATETIME2 DEFAULT GETDATE(),
    BasePrice DECIMAL(18, 2) NOT NULL,
    TotalPrice DECIMAL(18, 2) NOT NULL,
    PaymentStatus NVARCHAR(50) NOT NULL DEFAULT 'Pending',
    CheckinStatus NVARCHAR(50) NOT NULL DEFAULT 'NotCheckedIn',
    QRCodeData NVARCHAR(MAX) NULL,
    Notes NVARCHAR(MAX) NULL,
    IsDeleted BIT DEFAULT 0, -- Cờ Soft Delete
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL CONSTRAINT FK_Ve_UpdatedBy FOREIGN KEY REFERENCES AdminUsers(UserID)
);
GO

-- Tạo Index để tăng tốc độ truy vấn
CREATE INDEX IX_Ve_UsageDate ON Ve(UsageDate);
CREATE INDEX IX_Ve_CustomerEmail ON Ve(CustomerEmail);
CREATE INDEX IX_Ve_BookingCode ON Ve(BookingCode);
GO

CREATE TABLE ChiTietDonHang_DichVu (
    TicketServiceID BIGINT PRIMARY KEY IDENTITY(1,1),
    -- Đổi ON DELETE CASCADE thành NO ACTION để bảo vệ dữ liệu tài chính
    TicketID BIGINT CONSTRAINT FK_ChiTietDonHang_DichVu_Ve FOREIGN KEY (TicketID) REFERENCES Ve(TicketID) ON DELETE NO ACTION ON UPDATE CASCADE,
    ServiceID INT CONSTRAINT FK_ChiTietDonHang_DichVu_DichVu FOREIGN KEY (ServiceID) REFERENCES DichVu(ServiceID) ON DELETE NO ACTION ON UPDATE CASCADE,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    PriceAtBooking DECIMAL(18, 2) NOT NULL,
    UNIQUE (TicketID, ServiceID)
);
GO

CREATE TABLE GiaoDich (
    TransactionID BIGINT PRIMARY KEY IDENTITY(1,1),
    TicketID BIGINT NULL CONSTRAINT FK_GiaoDich_Ve FOREIGN KEY (TicketID) REFERENCES Ve(TicketID) ON DELETE SET NULL ON UPDATE CASCADE,
    PaymentGateway NVARCHAR(50) NOT NULL,
    GatewayTransactionID NVARCHAR(255) NULL,
    OrderInfo NVARCHAR(MAX) NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    TransactionDate DATETIME2 DEFAULT GETDATE(),
    Status NVARCHAR(50) NOT NULL,
    ResponseMessage NVARCHAR(MAX) NULL,
    ProcessedBy INT NULL CONSTRAINT FK_GiaoDich_ProcessedBy FOREIGN KEY REFERENCES AdminUsers(UserID)
);
GO

-- =====================================================================================
-- PHẦN 2: THÊM DỮ LIỆU MẪU (INSERT DATA)
-- =====================================================================================

-- Thêm dữ liệu cho bảng Roles
INSERT INTO Roles (RoleName) VALUES
(N'SuperAdmin'),
(N'TicketManager'),
(N'ReportViewer'),
(N'Customer');
GO

-- Thêm dữ liệu mẫu cho bảng AdminUsers
INSERT INTO AdminUsers (Username, PasswordHash, FullName, Email, RoleID, IsActive, CreatedAt)
VALUES
('superadmin', 'ANKMcsr9RDPAb2KMCTdQjTNMoIR/wG+CC3eXfd6eMC6kc9v65g/JlbefpCP5M6pJFw==', N'Lê Thanh Tú', 'thanhtule@minera.com', 1, 1, GETDATE()), -- Mật khẩu: "Password@123"
('ticketmanager01', 'ANKMcsr9RDPAb2KMCTdQjTNMoIR/wG+CC3eXfd6eMC6kc9v65g/JlbefpCP5M6pJFw==', N'Nguyễn Văn Hùng', 'hungnguyen@minera.com', 2, 1, GETDATE()), -- Mật khẩu: "Password@123"
('reportviewer01', 'ANKMcsr9RDPAb2KMCTdQjTNMoIR/wG+CC3eXfd6eMC6kc9v65g/JlbefpCP5M6pJFw==', N'Nguyễn Thị Kim Ngân', 'kimngan63241@gmail.com', 3, 1, GETDATE()); -- Mật khẩu: "Password@123"
GO

-- Thêm dữ liệu mẫu cho bảng KhachHang
INSERT INTO KhachHang (FullName, Email, PhoneNumber, PasswordHash, RegistrationDate, IsActive)
VALUES
(N'Nguyễn Văn An', 'nguyenvana@gmail.com', '0987654321', 'APG2d7F0AcOvfdhIfek+O4SF15JGiNNt6VHewpaWCVofgEeIXEVPadepFEZ0feJqZw==', GETDATE(), 1), -- Khách hàng đăng ký tài khoản, mật khẩu: "an123@"
(N'Dư Phước Tấn', 'phuoctan@gmail.com', '0347584695', NULL, GETDATE(), 1), 
(N'Nguyễn Thị Kim Ngân', 'kimngan63241@gmail.com', '0343893423', NULL, GETDATE(), 1), 
(N'Nguyễn Đình Hảo', 'haonguyendinh@gmail.com', '0325678348', NULL, GETDATE(), 1),
(N'Nguyễn Vi Danh', 'nguyenvidanh@gmail.com', '0983274365', NULL, GETDATE(), 1),
(N'Huỳnh Phan Đức Kiên', 'huynhphanduckien@gmail.com', '0765384794', NULL, GETDATE(), 1),
(N'Lê Võ Đức Anh', 'ducanhlevo@gmail.com', '0354892897', NULL, GETDATE(), 1),
(N'Trần Quang Thắng', 'tranquangthang@gmail.com', '0374859794', NULL, GETDATE(), 1),
(N'Nguyễn Văn Trọng', 'trongnguyenvan@gmail.com', '0965382926', NULL, GETDATE(), 1),
(N'Nguyễn Thị Nam', 'namnguyenthi@gmail.com', '0345674497', NULL, GETDATE(), 1); 
GO

-- Thêm dữ liệu mẫu cho bảng LoaiVe (Các trường Audit sẽ tự động lấy DEFAULT GETDATE())
INSERT INTO LoaiVe (TypeName, Price, Description, IsActive) VALUES
(N'Vé Vào Cổng - Người Lớn', 200000, N'Áp dụng cho người lớn cao trên 140cm. Bao gồm tham quan, ngâm chân khoáng nóng.', 1),
(N'Vé Vào Cổng - Trẻ Em', 100000, N'Áp dụng cho trẻ em cao từ 100cm đến 140cm.', 1),
(N'Combo Khám Khá Minera', 590000, N'Bao gồm vé vào cổng, 1 trứng gà luộc, tắm Onsen kiểu Nhật và 1 suất ăn trưa/tối.', 1),
(N'Vé Ưu Đãi Người Cao Tuổi', 140000, N'Áp dụng cho khách hàng trên 60 tuổi, cần xuất trình giấy tờ tùy thân.', 1);
GO

-- Thêm dữ liệu mẫu cho bảng DichVu 
INSERT INTO DichVu (ServiceName, Price, Description, IsActive) VALUES
(N'Luộc Trứng Gà Lòng Đào', 12000, N'Trải nghiệm luộc trứng bằng nước khoáng nóng 82 độ tự nhiên.', 1),
(N'Tắm Bùn Khoáng Nóng (Bồn 1-2 khách)', 400000, N'Thư giãn trong bồn bùn khoáng nóng riêng tư cho 1-2 người.', 1),
(N'Tắm Bùn Khoáng Nóng (Bồn 4-5 khách)', 800000, N'Thư giãn trong bồn bùn khoáng nóng cho nhóm 4-5 người.', 1),
(N'Tắm Khoáng Thảo Dược', 300000, N'Ngâm mình trong bồn khoáng nóng kết hợp với các loại thảo dược thiên nhiên.', 1),
(N'Ngâm Chân Khoáng Nóng', 50000, N'Dịch vụ ngâm chân tại khu vực chung Springs Land.', 1),
(N'Massage Chân (30 phút)', 250000, N'Liệu trình massage chân thư giãn trong 30 phút.', 1);
GO