import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  List<Map<String, dynamic>> mostBookedRooms = [];
  List<Map<String, dynamic>> mostActiveUsers = [];
  Map<String, int> peakTimes = {};

  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "Room Usage Analytics",
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 10),

          // Most Booked Rooms Table
          pw.Text(
            "Most Frequently Booked Rooms",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Room Name', 'Number of Bookings'],
            data: mostBookedRooms
                .map((r) => [r['name'], r['count'].toString()])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 20),

          // Most Active Users Table
          pw.Text(
            "Most Active Users",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['User Name', 'Number of Meetings'],
            data: mostActiveUsers
                .map((u) => [u['name'], u['count'].toString()])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.green800),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 20),

          // Peak Usage Times Table
          pw.Text(
            "Peak Usage Times",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Hour', 'Number of Bookings'],
            data: peakTimes.entries
                .map((t) => ["${t.key}:00", t.value.toString()])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.red800),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 30),

          // Footer or additional notes
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Generated on ${DateTime.now().toLocal().toString().split('.')[0]}",
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildMostBookedRoomsChart() {
    final data = mostBookedRooms;
    final maxY = data.isEmpty
        ? 1
        : data
        .map((e) => e['count'] as int? ?? 0)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final barGroups = data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final count = item['count'] as int? ?? 0;

      return BarChartGroupData(x: index, barRods: [
        BarChartRodData(toY: count.toDouble(), color: Colors.blue, width: 20),
      ]);
    }).toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: maxY + 2,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return Container();
                  final label = data[index]['name'] ?? '';
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),

            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // Similar chart widgets can be added for mostActiveUsers and peakTimes if needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Analytics"),
        actions: [
          IconButton(
            tooltip: "Export PDF",
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: loading ? null : _exportPDF,
          ),
          // You can add Excel export button here if needed
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // You can display charts here, for example:
            const Text(
              "Most Booked Rooms",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildMostBookedRoomsChart(),
            const SizedBox(height: 20),

            const Text(
              "Most Active Users",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...mostActiveUsers.map(
                  (u) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(u['name']),
                trailing: Text("${u['count']} meetings"),
              ),
            ),
            const Divider(),
            const Text(
              "Peak Usage Times",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...peakTimes.entries.map(
                  (t) => ListTile(
                leading: const Icon(Icons.access_time),
                title: Text("${t.key}:00"),
                trailing: Text("${t.value} bookings"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
