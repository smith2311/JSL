import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../../widgets/Dashboard/SIP Calculator/chart_legend.dart';
import '../../../../../../widgets/Dashboard/SIP Calculator/custom_dropdown.dart';
import '../../../../../../widgets/Dashboard/SIP Calculator/custom_slider.dart';
import '../../../../../../widgets/Dashboard/SIP Calculator/summary_card.dart';
import '../../../../../../widgets/Dashboard/SIP Calculator/year_card.dart';
import '../../../../data/models/yearly_data.dart';

class SipCalculatorScreen extends StatefulWidget {
  const SipCalculatorScreen({super.key});

  @override
  State<SipCalculatorScreen> createState() => _SipCalculatorScreenState();
}

class _SipCalculatorScreenState extends State<SipCalculatorScreen> {
  // Input values
  double _monthlyInvestment = 500;
  double _expectedReturn = 12;
  int _investmentPeriod = 10;
  double _expectedInflation = 10;
  bool _enableStepUp = false;
  String _stepUpFrequency = 'Yearly';
  double _stepUpPercentage = 10;

  // Error messages
  String? _monthlyInvestmentError;
  String? _expectedReturnError;
  String? _investmentPeriodError;
  String? _expectedInflationError;
  String? _stepUpPercentageError;

  // Controllers
  final TextEditingController _monthlyInvestmentController = TextEditingController(text: '500');
  final TextEditingController _expectedReturnController = TextEditingController(text: '12');
  final TextEditingController _investmentPeriodController = TextEditingController(text: '10');
  final TextEditingController _expectedInflationController = TextEditingController(text: '10');
  final TextEditingController _stepUpPercentageController = TextEditingController(text: '10');

  @override
  void dispose() {
    _monthlyInvestmentController.dispose();
    _expectedReturnController.dispose();
    _investmentPeriodController.dispose();
    _expectedInflationController.dispose();
    _stepUpPercentageController.dispose();
    super.dispose();
  }

  void _calculateSIP() {
    if (!_isFormValid()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SipResultsScreen(
          monthlyInvestment: _monthlyInvestment,
          expectedReturn: _expectedReturn,
          investmentPeriod: _investmentPeriod,
          expectedInflation: _expectedInflation,
          enableStepUp: _enableStepUp,
          stepUpFrequency: _stepUpFrequency,
          stepUpPercentage: _stepUpPercentage,
        ),
      ),
    );
  }

  bool _isFormValid() {
    if (_monthlyInvestmentError != null ||
        _expectedReturnError != null ||
        _investmentPeriodError != null ||
        _expectedInflationError != null ||
        (_enableStepUp && _stepUpPercentageError != null)) {
      return false;
    }

    if (_monthlyInvestmentController.text.isEmpty || _monthlyInvestmentController.text == '0') {
      return false;
    }

    if (_expectedReturnController.text.isEmpty || _expectedReturnController.text == '0') {
      return false;
    }

    if (_investmentPeriodController.text.isEmpty || _investmentPeriodController.text == '0') {
      return false;
    }

    if (_expectedInflationController.text.isEmpty) {
      return false;
    }

    if (_enableStepUp && (_stepUpPercentageController.text.isEmpty || _stepUpPercentageController.text == '0')) {
      return false;
    }

    if (_monthlyInvestment < 500 || _monthlyInvestment > 100000) {
      return false;
    }

    if (_expectedReturn < 1 || _expectedReturn > 30) {
      return false;
    }

    if (_investmentPeriod < 1 || _investmentPeriod > 40) {
      return false;
    }

    if (_expectedInflation < 0 || _expectedInflation > 20) {
      return false;
    }

    if (_enableStepUp) {
      if (_stepUpPercentage < 0 || _stepUpPercentage > 100) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'SIP Calculator',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderWithInput(
                        label: 'Monthly Investment',
                        value: _monthlyInvestment,
                        controller: _monthlyInvestmentController,
                        min: 500,
                        max: 100000,
                        divisions: 199,
                        errorText: _monthlyInvestmentError,
                        onSliderChanged: (value) {
                          setState(() {
                            _monthlyInvestment = value;
                            _monthlyInvestmentController.text = value.toInt().toString();
                            _monthlyInvestmentError = null;
                          });
                        },
                        onTextChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _monthlyInvestmentError = 'Please enter monthly investment';
                            });
                            return;
                          }
                          if (value == '0') {
                            setState(() {
                              _monthlyInvestment = 0;
                              _monthlyInvestmentError = 'Monthly Investment cannot be zero';
                            });
                            return;
                          }
                          final doubleValue = double.tryParse(value);
                          if (doubleValue == null) {
                            setState(() {
                              _monthlyInvestmentError = 'Please enter a valid number';
                            });
                            return;
                          }
                          if (doubleValue < 500) {
                            setState(() {
                              _monthlyInvestment = doubleValue;
                              _monthlyInvestmentError = 'Minimum investment is ₹500';
                            });
                            return;
                          }
                          if (doubleValue > 100000) {
                            setState(() {
                              _monthlyInvestment = doubleValue;
                              _monthlyInvestmentError = 'Maximum investment is ₹1,00,000';
                            });
                            return;
                          }
                          setState(() {
                            _monthlyInvestment = doubleValue;
                            _monthlyInvestmentError = null;
                          });
                        },
                        prefix: '₹',
                      ),
                      const SizedBox(height: 24),
                      SliderWithInput(
                        label: 'Expected Return (% p.a.)',
                        value: _expectedReturn,
                        controller: _expectedReturnController,
                        min: 1,
                        max: 30,
                        divisions: 29,
                        errorText: _expectedReturnError,
                        showTicks: false,
                        onSliderChanged: (value) {
                          setState(() {
                            _expectedReturn = value;
                            _expectedReturnController.text = value.toInt().toString();
                            _expectedReturnError = null;
                          });
                        },
                        onTextChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _expectedReturnError = 'Please enter expected return';
                            });
                            return;
                          }
                          if (value == '0') {
                            setState(() {
                              _expectedReturn = 0;
                              _expectedReturnError = 'Expected Return cannot be zero';
                            });
                            return;
                          }
                          final doubleValue = double.tryParse(value);
                          if (doubleValue == null) {
                            setState(() {
                              _expectedReturnError = 'Please enter a valid number';
                            });
                            return;
                          }
                          if (doubleValue < 1) {
                            setState(() {
                              _expectedReturn = doubleValue;
                              _expectedReturnError = 'Minimum return is 1%';
                            });
                            return;
                          }
                          if (doubleValue > 30) {
                            setState(() {
                              _expectedReturn = doubleValue;
                              _expectedReturnError = 'Maximum return is 30%';
                            });
                            return;
                          }
                          setState(() {
                            _expectedReturn = doubleValue;
                            _expectedReturnError = null;
                          });
                        },
                        suffix: '%',
                      ),
                      const SizedBox(height: 24),
                      TextFieldInput(
                        label: 'Investment Period (Years)',
                        controller: _investmentPeriodController,
                        onChanged: (value) {
                          final intValue = int.tryParse(value);
                          if (intValue != null && intValue > 0 && intValue <= 40) {
                            setState(() {
                              _investmentPeriod = intValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFieldInput(
                        label: 'Expected Inflation (% p.a.)',
                        controller: _expectedInflationController,
                        onChanged: (value) {
                          final doubleValue = double.tryParse(value);
                          if (doubleValue != null && doubleValue >= 0 && doubleValue <= 20) {
                            setState(() {
                              _expectedInflation = doubleValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enable Step-Up SIP',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Switch(
                            value: _enableStepUp,
                            onChanged: (value) {
                              setState(() {
                                _enableStepUp = value;
                              });
                            },
                            activeColor: const Color(0xFF0060A6),
                          ),
                        ],
                      ),
                      if (_enableStepUp) ...[
                        const SizedBox(height: 24),
                        DropdownField(
                          label: 'Step-Up Frequency',
                          value: _stepUpFrequency,
                          items: const ['Yearly', 'Quarterly'],
                          onChanged: (value) {
                            setState(() {
                              _stepUpFrequency = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        TextFieldInput(
                          label: 'Step-Up Percentage (%)',
                          controller: _stepUpPercentageController,
                          suffix: '%',
                          errorText: _stepUpPercentageError,
                          onChanged: (value) {
                            if (value.isEmpty) {
                              setState(() {
                                _stepUpPercentageError = 'Please enter step-up percentage';
                              });
                              return;
                            }
                            final doubleValue = double.tryParse(value);
                            if (doubleValue == null) {
                              setState(() {
                                _stepUpPercentageError = 'Please enter a valid number';
                              });
                              return;
                            }
                            if (doubleValue < 0) {
                              setState(() {
                                _stepUpPercentage = doubleValue;
                                _stepUpPercentageError = 'Step-up cannot be negative';
                              });
                              return;
                            }
                            if (doubleValue > 100) {
                              setState(() {
                                _stepUpPercentage = doubleValue;
                                _stepUpPercentageError = 'Maximum step-up is 100%';
                              });
                              return;
                            }
                            setState(() {
                              _stepUpPercentage = doubleValue;
                              _stepUpPercentageError = null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateSIP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Calculate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Results Screen
class SipResultsScreen extends StatefulWidget {
  final double monthlyInvestment;
  final double expectedReturn;
  final int investmentPeriod;
  final double expectedInflation;
  final bool enableStepUp;
  final String stepUpFrequency;
  final double stepUpPercentage;

  const SipResultsScreen({
    super.key,
    required this.monthlyInvestment,
    required this.expectedReturn,
    required this.investmentPeriod,
    required this.expectedInflation,
    required this.enableStepUp,
    required this.stepUpFrequency,
    required this.stepUpPercentage,
  });

  @override
  State<SipResultsScreen> createState() => _SipResultsScreenState();
}

class _SipResultsScreenState extends State<SipResultsScreen> {
  int totalInvestment = 0;
  int estimatedReturns = 0;
  int totalValue = 0;
  int inflationAdjustedValue = 0;
  List<YearlyData> yearlyBreakdown = [];
  int? touchedIndex;

  @override
  void initState() {
    super.initState();
    _calculateSIP();
  }

  void _calculateSIP() {
    final monthlyRate = widget.expectedReturn / 100 / 12;
    final months = widget.investmentPeriod * 12;

    double totalInvested = 0.0;
    double maturity = 0.0;

    final realReturnRate = (1 + widget.expectedReturn / 100) / (1 + widget.expectedInflation / 100) - 1;
    final monthlyRealRate = realReturnRate / 12;

    final List<double> sipHistory = [];
    double currentMonthlyInvestment = widget.monthlyInvestment;

    for (int month = 1; month <= months; month++) {
      sipHistory.add(currentMonthlyInvestment);

      if (widget.enableStepUp) {
        if ((widget.stepUpFrequency == 'Yearly' && month % 12 == 0) ||
            (widget.stepUpFrequency == 'Quarterly' && month % 3 == 0)) {
          currentMonthlyInvestment *= (1 + widget.stepUpPercentage / 100);
        }
      }
    }

    for (int i = 0; i < months; i++) {
      final sip = sipHistory[i];
      final remainingMonths = months - i;
      totalInvested += sip;
      maturity += sip * pow(1 + monthlyRate, remainingMonths);
    }

    final List<YearlyData> breakdown = [];
    for (int year = 1; year <= widget.investmentPeriod; year++) {
      final monthEnd = year * 12;
      double investmentTillNow = 0;
      double currentValue = 0;
      double inflationAdjustedVal = 0;

      for (int m = 0; m < monthEnd; m++) {
        final sip = sipHistory[m];
        final monthsLeft = monthEnd - m;
        investmentTillNow += sip;
        currentValue += sip * pow(1 + monthlyRate, monthsLeft);
        inflationAdjustedVal += sip * pow(1 + monthlyRealRate, monthsLeft);
      }

      breakdown.add(YearlyData(
        year: year,
        investment: investmentTillNow.round(),
        returns: (currentValue - investmentTillNow).round(),
        totalValue: currentValue.round(),
        inflationAdjusted: inflationAdjustedVal.round(),
        monthlySip: sipHistory[(year - 1) * 12].round(),
      ));
    }

    setState(() {
      totalInvestment = totalInvested.round();
      estimatedReturns = (maturity - totalInvested).round();
      totalValue = maturity.round();
      inflationAdjustedValue = (maturity / pow(1 + widget.expectedInflation / 100, widget.investmentPeriod)).round();
      yearlyBreakdown = breakdown;
    });
  }

  String _formatAmount(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatNumber(int value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)} K';
    }
    return value.toString();
  }

  double _calculateResponsiveBarWidth() {
    final totalYears = widget.investmentPeriod;
    if (totalYears == 1) {
      return 80.0;
    } else if (totalYears == 2) {
      return 70.0;
    } else if (totalYears == 3) {
      return 60.0;
    } else if (totalYears <= 5) {
      return 50.0;
    } else if (totalYears <= 8) {
      return 35.0;
    } else if (totalYears <= 12) {
      return 22.0;
    } else if (totalYears <= 20) {
      return 12.0;
    } else if (totalYears <= 30) {
      return 8.0;
    } else {
      return 6.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'SIP Calculator',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: yearlyBreakdown.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'Total Investment',
                      value: '₹$totalInvestment',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      label: 'Estimated Returns',
                      value: '₹$estimatedReturns',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'Total Value',
                      value: '₹$totalValue',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      label: 'Inflation-Adjusted Value',
                      value: '₹$inflationAdjustedValue',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Results Visualization',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 350,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceEvenly,
                          maxY: yearlyBreakdown.last.totalValue.toDouble() * 1.1,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.white,
                              tooltipBorder: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              tooltipPadding: const EdgeInsets.all(12),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final yearData = yearlyBreakdown[group.x.toInt()];
                                return BarTooltipItem(
                                  '',
                                  const TextStyle(),
                                  children: [
                                    TextSpan(
                                      text: 'Year ${yearData.year}\n',
                                      style: const TextStyle(
                                        color: Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Invested: ₹${_formatNumber(yearData.investment)}\n',
                                      style: const TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 12,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Returns: ₹${_formatNumber(yearData.returns)}\n',
                                      style: const TextStyle(
                                        color: Color(0xFF666666),
                                        fontSize: 12,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Total: ₹${_formatNumber(yearData.totalValue)}',
                                      style: const TextStyle(
                                        color: Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.spot == null) {
                                  touchedIndex = null;
                                  return;
                                }
                                touchedIndex = response.spot!.touchedBarGroupIndex;
                              });
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1.0,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  final index = value.toInt();
                                  if (index >= yearlyBreakdown.length) {
                                    return const SizedBox.shrink();
                                  }

                                  // Determine which labels to show based on total years
                                  final totalYears = widget.investmentPeriod;
                                  bool shouldShow = false;

                                  if (totalYears <= 10) {
                                    shouldShow = true; // Show all
                                  } else if (totalYears <= 15) {
                                    shouldShow = index % 2 == 0; // Show every 2nd
                                  } else if (totalYears <= 25) {
                                    shouldShow = index % 3 == 0 || index == yearlyBreakdown.length - 1; // Show every 3rd + last
                                  } else {
                                    shouldShow = index % 5 == 0 || index == yearlyBreakdown.length - 1; // Show every 5th + last
                                  }

                                  if (!shouldShow) {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Y${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      '₹${_formatAmount(value)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: false,
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: yearlyBreakdown.asMap().entries.map((entry) {
                            final index = entry.key;
                            final year = entry.value;
                            final isTouched = index == touchedIndex;

                            final barWidth = _calculateResponsiveBarWidth();

                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: year.totalValue.toDouble(),
                                  width: barWidth,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  rodStackItems: [
                                    BarChartRodStackItem(
                                      0,
                                      year.investment.toDouble(),
                                      const Color(0xFF0060A6),
                                    ),
                                    BarChartRodStackItem(
                                      year.investment.toDouble(),
                                      year.totalValue.toDouble(),
                                      const Color(0xFFEB1651),
                                    ),
                                  ],
                                ),
                              ],
                              showingTooltipIndicators: isTouched ? [0] : [],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChartLegend(label: 'Invested', color: Color(0xFF0060A6)),
                        SizedBox(width: 24),
                        ChartLegend(label: 'Returns', color: Color(0xFFEB1651)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ...yearlyBreakdown.map((data) => YearCard(data: data)),
            ],
          ),
        ),
      ),
    );
  }
}