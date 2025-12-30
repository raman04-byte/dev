class VoucherSignatureModel {
  final String name;
  final String signatureImageUrl;

  VoucherSignatureModel({required this.name, required this.signatureImageUrl});

  factory VoucherSignatureModel.fromJson(Map<String, dynamic> json) {
    return VoucherSignatureModel(
      name: json['name'] ?? '',
      signatureImageUrl: json['signature_image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'signature_image_url': signatureImageUrl};
  }
}
