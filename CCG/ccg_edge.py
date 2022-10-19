import util
import random

if __name__ == '__main__':
    """ The input parameter """
    EN_num = 8  # index j
    AP_num = 8  # index i
    expr_times = 1
    # const = [4,8,12,16,20]
    # ration = [0,1,2,3,4,5,6]
    # commonTask = [0,1,2,3,4,5,6,7,8]
    # Ration = [1, 2, 4, 6, 8, 10]
    #Ration = [1.000000e-01, 3.000000e-01, 5.000000e-01, 1, 1.500000e+00]
    Ration = [1]
    # task_list = [1,1,1,1,4,1,4,1,1,1,1,4,1,1,1,1,1,5,1,4,1,1,1,1,1,1,1,3,1,1,1,4,1,1,1,1,1,3,1,1,1,1,
    #              1,3,1,1,1,1,1,2,1,1,1,1,1,1,1,1,3,1,1,1,1,2,1,3,1,1,1,1,1,1,1,1,1,5,1,1,1,3,1,1,1,1,1,1,1,3,1,
    #              1,1,1,1,1,1,2,1,4,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,5,1,1,1,6,1,1,1,1,3,1]

    placeAndStore_cost = [0.31, 0.32, 0.3, 0.32, 0.31, 0.29, 0.3, 0.32]              # h_j = s_j + f_j  0.1 <= s_j <= 0.12  0.2 <= f_j <= 0.25
    purchase_cost = [0.0412, 0.0443, 0.0478, 0.0411, 0.042, 0.0432, 0.0435, 0.0476]  # 0.04 <= p_j <= 0.06
    #placeAndStore_cost = [0.31, 0.32, 0.3, 0.32, 0.31]
    #purchase_cost = [0.0412, 0.0443, 0.0478, 0.0411, 0.042]
    purchase_cloud_cost = 0.05                                                       # p_0
    trans_delay_cloud, trans_delay_en = util.generate_network(AP_num, EN_num)        # d_ij d_i0
    print(trans_delay_en)
    max_avg_delay = 3                                                                # D_m 0.03
    alpha = 0.2
    # demand_nominal, demand_var = util.generate_random_demand_nominal(AP_num, alpha, task_num)  # λ_f, λ_hat
    beta = 0.1
    # beta = 0.01 / sum(demand_nominal)                                              # β 0.01
    print('beta:{}'.format(beta))
    w = 20                                                                           # w 1MHz
    big_B = 100000                                                                   # budget 100
    # uncertainty_budget = int(task_num / 2)                                         # Γ
    resource_capacity = [4000 for i in range(EN_num)]             # C_j
    resource_capacity_per_second = [random.random() * 87.5 + 525 / 4 for i in range(EN_num)]   # random.random() * 87.5 + 525 / 4 for i in range(EN_num)
    print('resource_capacity_per_second : {}'.format(resource_capacity_per_second))

    res = {}

    for ration in Ration:
        print('Const is :{}'.format(ration))
        time_sum = 0
        for time in range(expr_times):
            print('Expr time is :{}'.format(time+1))
            task_list = util.xlsx_read(time + 1, ration, 1)
            print(task_list)
            expr_res = util.run_list(EN_num, AP_num, placeAndStore_cost, purchase_cost, purchase_cloud_cost,
                                    trans_delay_cloud, trans_delay_en, max_avg_delay, alpha,
                                    beta, w, big_B, resource_capacity, resource_capacity_per_second,
                                    task_list)
            while expr_res > 1e5:
                expr_res = util.run_list(EN_num, AP_num, placeAndStore_cost, purchase_cost, purchase_cloud_cost,
                                         trans_delay_cloud, trans_delay_en, max_avg_delay, alpha,
                                         beta, w, big_B, resource_capacity, resource_capacity_per_second,
                                         task_list)
                print('____________________________________________________________')
            time_sum += expr_res
        res[ration] = time_sum / expr_times

    print('Expr res is:\n{}'.format(res))
    # print('Avg time is: {}'.format(sum(res)/expr_times))




