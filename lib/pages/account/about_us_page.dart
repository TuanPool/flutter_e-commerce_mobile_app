import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  final List<Map<String, String>> teamMembers = [
    {
      "name": "Lại Quang Tuấn",
      "mssv": "22010438",
      "role": "Kết nối Firebase, làm trang Web Admin, trang chủ.",
    },
    {
      "name": "Phạm Việt Phương",
      "mssv": "22010465",
      "role": "Đăng nhập, đăng kí, trang Tài khoản, tạo dữ liệu cho Firestore",
    },
    {
      "name": "Nguyễn Hà Ninh",
      "mssv": "22010470",
      "role": "Làm trang thông tin sản phẩm, Thanh toán, lịch sử",
    },
    {
      "name": "Nguyễn Thị Thủy Tiên",
      "mssv": "22010268",
      "role": "Giỏ hàng, thông báo,tạo dữ liệu cho Firestore",
    },
    {
      "name": "Trần Hồng Ngọc",
      "mssv": "22010245",
      "role": "Trang cửa hàng, phân loại sản phẩm, tìm kiếm.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About_Us".tr()),
      
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: teamMembers.length,
          itemBuilder: (context, index) {
            final member = teamMembers[index];
            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                title: Text(member["name"]!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text("MSSV: ${member["mssv"]}\nĐóng góp: ${member["role"]}"),
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(member["name"]![0], style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
