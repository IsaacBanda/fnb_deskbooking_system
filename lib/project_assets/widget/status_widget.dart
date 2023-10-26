import '../../exports/export.dart';

class StatusWidget extends StatelessWidget {
  const StatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
                  width: 220,
                  height: 240,
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                    color: AppColors.neutral,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomTextField(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        text: 'Availability Key',
                        size: 20,
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.green,
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              const CustomTextField(
                                  text: "Available",
                                  fontWeight: FontWeight.w300,
                                  size: 16,
                                  color: AppColors.white)
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.secondaryColor,
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              const CustomTextField(
                                text: "Partially",
                                fontWeight: FontWeight.w300,
                                size: 16,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.red,
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              const CustomTextField(
                                text: "Busy",
                                fontWeight: FontWeight.w300,
                                size: 16,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.blue,
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              const CustomTextField(
                                text: "Occupied",
                                fontWeight: FontWeight.w300,
                                size: 16,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.grey,
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              const CustomTextField(
                                text: "Disabled",
                                fontWeight: FontWeight.w300,
                                size: 16,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                );
  }
}