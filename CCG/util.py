import random
from gurobipy import *
import numpy as np
import xlrd

MAX_VALUE = 100000.0
MIN_VALUE = 1e-3

# randomly generate the trans delay en between 2-5s and cloud 80
def generate_network(AP_num, EN_num):
    trans_delay_cloud = []
    trans_delay_en = []
    ap_cloud_list = []
    for i in range(AP_num):
        random_link = random.sample(range(-1,5),2)
        print(random_link)
        if -1 in random_link:
            random_link.remove(-1)
            ap_cloud_list.append(i)
        ap_link_list = [0 for k in range(EN_num)]
        for j in range(EN_num):
            if j in random_link:
                ap_link_list[j] = float(random.randint(33,200)) * 0.01
            else:
                ap_link_list[j] = MAX_VALUE
        trans_delay_en.append(ap_link_list)
    for i in range(AP_num):
        if i in ap_cloud_list:
            trans_delay_cloud.append(3)
        else:
            trans_delay_cloud.append(MAX_VALUE)
    return trans_delay_cloud, trans_delay_en

def split_task_num_into_APnum(AP_num, task_num):
    res = []
    tot = 0
    while AP_num > 1:
        tmp = random.randint(0,math.floor((task_num-tot)/(AP_num/2)))
        tot += tmp
        AP_num -= 1
        res.append(tmp)
    res.append(task_num-tot)
    return res


# randomly generate the demand_nominal and demand_var
def generate_random_demand_nominal(AP_num, alpha, task_num):
    demand_var = []
    demand_nominal = split_task_num_into_APnum(AP_num, task_num)
    print('Demand_nominal : {}'.format(demand_nominal))
    # for i in range(AP_num):
    #     rand = random.randint(500, 1000)
    #     demand_nominal.append(rand)
    #     demand_var.append(rand*alpha)
    for i in range(AP_num):
        demand_var.append(demand_nominal[i] * alpha)
    return demand_nominal, demand_var

# generate the worst lambda in first
def generate_worst_lambda_init(demand_nominal, demand_var, uncertainty_budget, AP_num, lambda_master):
    arr = np.array(demand_nominal)
    top_ub_idx = arr.argsort()[::-1][0:uncertainty_budget]
    for i in range(AP_num):
        if(i in top_ub_idx):
            lambda_master[i] = demand_nominal[i] + demand_var[i]
        else:
            lambda_master[i] = demand_nominal[i]

def generate_M(AP_num, EN_num):
    M_0 = [0] * AP_num
    M_1 = [[0] * EN_num for _ in range(AP_num)]
    M_2 = 1000000                     # 100
    M_3 = [0] * EN_num
    M_4 = 1000000                       # 1

    for i in range(AP_num):
        M_0[i] = 2000000              # 0.002
        for j in range(EN_num):
            M_1[i][j] = 100000        # 100
            M_3[j] = 1000000           # 100
    return M_0, M_1, M_2, M_3, M_4

def print_sub_sol(model, lambda_sub, AP_num, x):
    lambda_sol = {}
    if(model.status != 2):
        print('The problem is infeasible or unbounded!')
        print('Status: {}'.format(model.status))
        for i in range(AP_num):
            lambda_sol[i] = 0
    else:
        print('Obj(sub) : {}'.format(model.ObjVal), end='\t | ')
        for key in lambda_sub.keys():
            # print('demand: {}, perturbation = {}'.format(d[key].x, g[key].x))
            lambda_sol[key] = lambda_sub[key].x
    return lambda_sol

def xlsx_read(expTimes, const, userNum):
    task = []
    for user in range(userNum):
        if (const - 0.1 <1e-5):
            tmp = '1.000000e-01'
        elif(const - 0.3 < 1e-5):
            tmp = '3.000000e-01'
        elif(const - 0.5 < 1e-5):
            tmp = '5.000000e-01'
        elif(const - 1 < 1e-5):
            tmp = '1'
        else:
            tmp = '1.500000e+00'

        filename = '6c\\' + str(expTimes) + '_' + tmp + '_' + str(user + 1) + '.xls'
        workbook = xlrd.open_workbook(filename, formatting_info=True)
        worksheet = workbook.sheet_by_index(0)
        for row in range(worksheet.nrows):
            values = worksheet.row_values(row)
            for value in values:
                print(value)
                task.append(value)
    return task


def run_list(EN_num, AP_num, placeAndStore_cost, purchase_cost, purchase_cloud_cost,
                        trans_delay_cloud, trans_delay_en, max_avg_delay, alpha,
                        beta, w, big_B, resource_capacity, resource_capacity_per_second, task_list):

    task_list_time = []
    for task in task_list:

        #uncertainty_budget = int(task / 2)                                                          # Γ
        uncertainty_budget = 0
        demand_nominal, demand_var = generate_random_demand_nominal(AP_num, alpha, task)            # λ_f, λ_hat

        y_sol, x = ccg(EN_num, AP_num, placeAndStore_cost, purchase_cost, purchase_cloud_cost,
                            trans_delay_cloud, trans_delay_en, max_avg_delay, alpha, demand_nominal, demand_var,
                            beta, w, big_B, uncertainty_budget, resource_capacity, resource_capacity_per_second)

        t_process = []
        for j in range(EN_num):
            t_process.append(y_sol[j] / resource_capacity_per_second[j])
            print('The edge server process time is : {}'.format(t_process[j]))

        t_trans = []
        for j in range(EN_num):
            tmpList = []
            for i in range(AP_num):
                tmpList.append(x[i][j])
            max_trans_time = max(tmpList)
            t_trans.append(max_trans_time * 2)
            print('The edge server {} trans time is : {}'.format(j, t_trans[j]))

        t_tot = []
        for j in range(EN_num):
            t_tot.append(t_trans[j] + t_process[j])
            print('The edge server {} total time is : {}'.format(j,t_tot[j]))

        max_computing_time = max(t_tot)
        print('\nThe task num is: {}\t computing time is: {}'.format(task, max_computing_time))

        task_list_time.append(max_computing_time)
    return sum(task_list_time)


def ccg(EN_num, AP_num, placeAndStore_cost, purchase_cost, purchase_cloud_cost,
        trans_delay_cloud, trans_delay_en, max_avg_delay, alpha, demand_nominal, demand_var,
        beta, w, big_B, uncertainty_budget, resource_capacity, resource_capacity_per_second):


    """ build initial master problem """
    """ Create variables """
    master = Model('master problem')
    master.setParam('Outputflag', 0)
    x_master = {}
    x_cloud_master = {}
    z = {}
    y = {}
    lambda_master = {}
    generate_worst_lambda_init(demand_nominal, demand_var, uncertainty_budget, AP_num, lambda_master)

    eta = master.addVar(lb=0, vtype=GRB.CONTINUOUS, name='eta')

    for j in range(EN_num):
        y[j] = master.addVar(lb=0, vtype=GRB.CONTINUOUS, name='y_%s' % (j))
        z[j] = master.addVar(vtype=GRB.BINARY, name='z_%s' % (j))
    y_cloud = master.addVar(lb=0, vtype=GRB.CONTINUOUS, name='y_cloud')

    """ Set objective """
    obj = LinExpr()
    for j in range(EN_num):
        obj.addTerms(placeAndStore_cost[j], z[j])
        obj.addTerms(purchase_cost[j], y[j])
    obj.addTerms(purchase_cloud_cost, y_cloud)
    obj.addTerms(1, eta)

    master.setObjective(obj, GRB.MINIMIZE)

    """ Add Constraints  """
    # cons 1
    for j in range(EN_num):
        master.addConstr(y[j] <= resource_capacity[j] * z[j])

    expr = LinExpr()
    for j in range(EN_num):
        expr.addTerms(1, z[j])
    master.addConstr(expr >= 2)

    expr = LinExpr()
    expr.addTerms(purchase_cloud_cost, y_cloud)
    for j in range(EN_num):
        expr.addTerms(placeAndStore_cost[j], z[j])
        expr.addTerms(purchase_cost[j], y[j])
    master.addConstr(expr <= big_B)

    """ Add initial value Constraints  """
    # create new variables x
    iter_cnt = 0
    for i in range(AP_num):
        for j in range(EN_num):
            x_master[iter_cnt, i, j] = master.addVar(lb=0
                                                     , ub=GRB.INFINITY
                                                     , vtype=GRB.CONTINUOUS
                                                     , name='x_%s_%s_%s' % (iter_cnt, i, j))
    for i in range(AP_num):
        x_cloud_master[iter_cnt, i] = master.addVar(lb=0
                                                    , ub=GRB.INFINITY
                                                    , vtype=GRB.CONTINUOUS
                                                    , name='x_cloud_%s_%s' %(iter_cnt, i))
    # create new constraints
    expr = LinExpr()
    for i in range(AP_num):
        expr.addTerms(trans_delay_cloud[i], x_cloud_master[iter_cnt, i])
        for j in range(EN_num):
            expr.addTerms(trans_delay_en[i][j], x_master[iter_cnt, i, j])
    master.addConstr(eta >= beta * expr)


    for i in range(AP_num):
        expr = LinExpr()
        expr.addTerms(1, x_cloud_master[iter_cnt, i])
        for j in range(EN_num):
            expr.addTerms(1, x_master[iter_cnt, i, j])
        master.addConstr(expr == lambda_master[i])

    expr = LinExpr()
    for i in range(AP_num):
        expr.addTerms(1, x_cloud_master[iter_cnt, i])
    master.addConstr(w * expr <= y_cloud)

    for j in range(EN_num):
        expr = LinExpr()
        for i in range(AP_num):
            expr.addTerms(1, x_master[iter_cnt, i, j])
        master.addConstr(w * expr <= y[j])

    expr_0 = LinExpr()
    expr_1 = 0
    for i in range(AP_num):
        expr_0.addTerms(trans_delay_cloud[i], x_cloud_master[iter_cnt, i])
        expr_1 += lambda_master[i]
        for j in range(EN_num):
            expr_0.addTerms(trans_delay_en[i][j], x_master[iter_cnt, i, j])
    master.addConstr(expr_0 <= max_avg_delay * expr_1)

    """ solve the model and output """
    master.optimize()
    print('Obj = {}'.format(master.ObjVal))
    print('-----  solution ----- ')
    for key in z.keys():
        print('EN service placement : {}, res: {}, capacity: {}'.format(key, z[key].x, y[key].x))
    print('Cloud service placement capacity: {}'.format(y_cloud.x))


    """ Column-and-constraint generation """
    LB = -np.inf
    UB = np.inf
    iter_cnt = 0
    max_iter = 10
    cut_pool = {}
    eps = 0.0001
    Gap = np.inf

    y_sol = {}
    for key in y.keys():
        y_sol[key] = y[key].x
    print("=================")
    print(y_sol)
    y_cloud_sol = y_cloud.x

    """ solve the master problem and update bound """
    master.optimize()

    """ 
     Update the Lower bound 
    """
    LB = master.ObjVal
    print('LB: {}'.format(LB))

    ''' create the subproblem '''
    subProblem = Model('sub problem')
    subProblem.setParam('Outputflag', 0)
    x = {}              # transportation decision variables in subproblem
    x_cloud = {}
    lambda_sub = {}     # true demand
    t = {}              # uncertainty part: var part
    pi_var = {}         # dual variable
    delta = {}          # dual variable
    u_0 = {}            # aux var
    u_1 = {}            # aux var
    u_3 = {}            # aux var
    M_0, M_1, M_2, M_3, M_4 = generate_M(AP_num, EN_num)

    # add var u
    for i in range(AP_num):
        u_0[i] = subProblem.addVar(vtype=GRB.BINARY, name='u_0_%s'%i)
        for j in range(EN_num):
            u_1[i,j] = subProblem.addVar(vtype=GRB.BINARY, name='u_1_%s_%s' % (i,j))
    for j in range(EN_num):
        u_3[j] = subProblem.addVar(vtype=GRB.BINARY, name='u_3_%s' % j)
    u_2 = subProblem.addVar(vtype=GRB.BINARY, name='u_2')
    u_4 = subProblem.addVar(vtype=GRB.BINARY, name='u_4')

    # add var pi
    pi_0 = subProblem.addVar(lb=0, vtype=GRB.CONTINUOUS, name='pi_0')
    # cons of pi_0
    subProblem.addConstr(pi_0 <= (1 - u_2) * M_2)
    for j in range(EN_num):
        pi_var[j] = subProblem.addVar(lb=0, vtype=GRB.CONTINUOUS, name='pi_var_%s'%j)
        subProblem.addConstr(pi_var[j] <= (1-u_3[j]) * M_3[j])
    # add var miu
    miu = subProblem.addVar(lb=0, vtype=GRB.CONTINUOUS, name='miu')
    subProblem.addConstr(pi_0 <= (1-u_4) * M_4)
    # add var delta
    for i in range(AP_num):
        delta[i] = subProblem.addVar(lb=0, vtype=GRB.CONTINUOUS, name='delta_%s'%i)

    # add var x
    for i in range(AP_num):
        x_cloud[i] = subProblem.addVar(lb=0, vtype=GRB.CONTINUOUS, name='x_%s' % (i))
        subProblem.addConstr(x_cloud[i] <= (1-u_0[i]) * M_0[i])
        for j in range(EN_num):
            x[i,j] = subProblem.addVar(lb=0, vtype=GRB.CONTINUOUS, name='x_%s_%s' % (i, j))
            subProblem.addConstr(x[i,j] <= (1-u_1[i,j]) * M_1[i][j])
    # add var t
    for i in range(AP_num):
        t[i] = subProblem.addVar(lb=0, ub=1, vtype=GRB.CONTINUOUS, name='t_%s'%i)

    # add var lambda
    for i in range(AP_num):
        lambda_sub[i] = subProblem.addVar(lb=0, ub=GRB.INFINITY, vtype=GRB.CONTINUOUS, name='lambda_sub_%s'%(i))

    """ set objective """
    sub_obj = LinExpr()
    for i in range(AP_num):
        sub_obj.addTerms(trans_delay_cloud[i], x_cloud[i])
        for j in range(EN_num):
            sub_obj.addTerms(trans_delay_en[i][j], x[i, j])

    subProblem.setObjective(sub_obj*beta, GRB.MAXIMIZE)

    """ add constraints to subproblem """
    # cons1 (123)
    for i in range(AP_num):
        expr = LinExpr()
        expr.addConstant(beta * trans_delay_cloud[i])
        expr.addTerms(w, pi_0)
        expr.addTerms(trans_delay_cloud[i], miu)
        expr.addTerms(-1, delta[i])
        subProblem.addConstr(0 <= expr)
        subProblem.addConstr(expr <= u_0[i]*M_0[i])
    # cons2 (125)
    for i in range(AP_num):
        for j in range(EN_num):
            expr = LinExpr()
            expr.addConstant(beta * trans_delay_en[i][j])
            expr.addTerms(w, pi_var[j])
            expr.addTerms(trans_delay_en[i][j], miu)
            expr.addTerms(-1, delta[i])
            subProblem.addConstr(0 <= expr)
            subProblem.addConstr(expr <= u_1[i,j] * M_1[i][j])
    # cons3 (127)
    expr = LinExpr()
    for i in range(AP_num):
        expr.addTerms(-1 * w, x_cloud[i])
    subProblem.addConstr(0 <= y_cloud_sol + expr, name='sub_capacity_cloud_1')
    subProblem.addConstr(y_cloud_sol + expr <= u_2 * M_2, name='sub_capacity_cloud_2')
    # cons4 (129)
    for j in range(EN_num):
        expr = LinExpr()
        for i in range(AP_num):
            expr.addTerms(-1 * w, x[i,j])
        subProblem.addConstr(0 <= y_sol[j] + expr, name='sub_capacity_1_%s' % j)
        subProblem.addConstr(y_sol[j] + expr <= u_3[j] * M_3[j], name='sub_capacity_2_%s' % j)
    # cons5 (131)
    expr_0 = LinExpr()
    expr_1 = LinExpr()
    expr_2 = LinExpr()
    for i in range(AP_num):
        expr_0.addTerms(max_avg_delay, lambda_sub[i])
        expr_1.addTerms(-1 * trans_delay_cloud[i], x_cloud[i])
        expr_2.addTerms(-1 * trans_delay_en[i][j], x[i, j])
    subProblem.addConstr(0 <= expr_0 + expr_1 + expr_2)
    subProblem.addConstr(expr_0 + expr_1 + expr_2 <= u_4 * M_4)
    # cons6 (135)
    for i in range(AP_num):
        expr = LinExpr()
        for j in range(EN_num):
            expr.addTerms(1, x[i,j])
        expr.addTerms(1, x_cloud[i])
        subProblem.addConstr(expr == lambda_sub[i])


    """ demand constraints """
    expr = LinExpr()
    for i in range(AP_num):
        expr.addTerms(1, t[i])
        subProblem.addConstr(lambda_sub[i] == demand_nominal[i] + t[i] * demand_var[i])
    subProblem.addConstr(expr <= uncertainty_budget)

    # subProblem.write('SP.lp')
    subProblem.optimize()

    print('\n\n\n *******            C&CG starts          *******  ')
    print('\n **                Initial Solution             ** ')

    lambda_sol = print_sub_sol(subProblem, lambda_sub, AP_num, x)
    print(lambda_sol)

    """ 
     Update the initial Upper bound 
    """
    UB = min(UB, subProblem.ObjVal + master.ObjVal - eta.x)
    print('eta = {}'.format(eta.x), end='\t | ')
    print('UB (iter {}): {}'.format(iter_cnt, UB))

    # close the outputflag
    master.setParam('Outputflag', 0)
    subProblem.setParam('Outputflag', 0)
    """
     Main loop of CCG algorithm 
    """
    while (UB - LB > eps and iter_cnt <= max_iter and Gap > round(1)): #UB - LB > eps
        iter_cnt += 1
        # print('\n\n --- iter : {} --- \n'.format(iter_cnt))
        print('\n iter : {} '.format(iter_cnt), end='\t | ')

        # create new variables x
        for i in range(AP_num):
            for j in range(EN_num):
                x_master[iter_cnt, i, j] = master.addVar(lb=0
                                                         , ub=GRB.INFINITY
                                                         , vtype=GRB.CONTINUOUS
                                                         , name='x_%s_%s_%s' % (iter_cnt, i, j))
        for i in range(AP_num):
            x_cloud_master[iter_cnt, i] = master.addVar(lb=0
                                                        , ub=GRB.INFINITY
                                                        , vtype=GRB.CONTINUOUS
                                                        , name='x_cloud_%s_%s' %(iter_cnt, i))


        # if subproblem is frasible and bound, create variables xk+1 and add the new constraints
        if (subProblem.status == 2 and subProblem.ObjVal < 1000000000):
            # create new constraints
            expr = LinExpr()
            for i in range(AP_num):
                expr.addTerms(trans_delay_cloud[i], x_cloud_master[iter_cnt, i])
                for j in range(EN_num):
                    expr.addTerms(trans_delay_en[i][j], x_master[iter_cnt, i, j])
            master.addConstr(eta >= beta * expr)

            for i in range(AP_num):
                expr = LinExpr()
                expr.addTerms(1, x_cloud_master[iter_cnt, i])
                for j in range(EN_num):
                    expr.addTerms(1, x_master[iter_cnt, i, j])
                master.addConstr(expr == lambda_sol[i])

            expr = LinExpr()
            for i in range(AP_num):
                expr.addTerms(1, x_cloud_master[iter_cnt, i])
            master.addConstr(w * expr <= y_cloud)

            for j in range(EN_num):
                expr = LinExpr()
                for i in range(AP_num):
                    expr.addTerms(1, x_master[iter_cnt, i, j])
                master.addConstr(w * expr <= y[j])

            expr_0 = LinExpr()
            expr_1 = 0
            for i in range(AP_num):
                expr_0.addTerms(trans_delay_cloud[i], x_cloud_master[iter_cnt, i])
                expr_1 += lambda_sol[i]
                for j in range(EN_num):
                    expr_0.addTerms(trans_delay_en[i][j], x_master[iter_cnt, i, j])
            master.addConstr(expr_0 <= max_avg_delay * expr_1)

            # solve the resulted master problem
            master.optimize()

            print('Obj(master): {}'.format(master.ObjVal), end='\t | ')
            """ Update the LB """
            LB = master.ObjVal
            print('LB (iter {}): {}'.format(iter_cnt, LB), end='\t | ')

            """ Update the subproblem """
            # first, get y_sol from updated master problem
            y_sol = {}
            for key in y.keys():
                y_sol[key] = y[key].x
            print("=================")
            print(y_sol)
            y_cloud_sol = y_cloud.x



            # change the coefficient of subproblem
            for j in range(EN_num):
                constr_name_1 = 'sub_capacity_1_' + str(j)
                constr_name_2 = 'sub_capacity_2_' + str(j)
                subProblem.remove(subProblem.getConstrByName(constr_name_1))
                subProblem.remove(subProblem.getConstrByName(constr_name_2))

            constr_name_1 = 'sub_capacity_cloud_1'
            constr_name_2 = 'sub_capacity_cloud_2'
            subProblem.remove(subProblem.getConstrByName(constr_name_1))
            subProblem.remove(subProblem.getConstrByName(constr_name_2))

            # add new constraints
            # cons3 (127)
            expr = LinExpr()
            for i in range(AP_num):
                expr.addTerms(-1 * w, x_cloud[i])
            subProblem.addConstr(0 <= y_cloud_sol + expr, name='sub_capacity_cloud_1')
            subProblem.addConstr(y_cloud_sol + expr <= u_2 * M_2, name='sub_capacity_cloud_2')
            # cons4 (129)
            for j in range(EN_num):
                expr = LinExpr()
                for i in range(AP_num):
                    expr.addTerms(-1 * w, x[i, j])
                subProblem.addConstr(0 <= y_sol[j] + expr, name='sub_capacity_1_%s' % j)
                subProblem.addConstr(y_sol[j] + expr <= u_3[j] * M_3[j], name='sub_capacity_2_%s' % j)

            """ Update the lower bound """
            subProblem.optimize()

            lambda_sol = print_sub_sol(subProblem, lambda_sub, AP_num, x)
            print(lambda_sol)
            """ 
            Update the Upper bound 
            """
            if (subProblem.status == 2):
                UB = min(UB, subProblem.ObjVal + master.ObjVal - eta.x)
                # print('eta = {}'.format(eta.x))
            print('UB (iter {}): {}'.format(iter_cnt, UB), end='\t | ')
            Gap = round(100 * (UB - LB) / UB, 2)
            print('eta = {}'.format(eta.x), end='\t | ')
            print(' Gap: {} %  '.format(Gap), end='\t')

        # If the subproblem is unbounded
        if (subProblem.status == 4):
            # create worst case related constraints
            # cons 2
            for i in range(AP_num):
                expr = LinExpr()
                expr.addTerms(1, x_cloud_master[iter_cnt, i])
                for j in range(EN_num):
                    expr.addTerms(1, x_master[iter_cnt, i, j])
                master.addConstr(expr == lambda_sol[i])

            expr = LinExpr()
            for i in range(AP_num):
                expr.addTerms(1, x_cloud_master[iter_cnt, i])
            master.addConstr(w * expr <= y_cloud)

            for j in range(EN_num):
                expr = LinExpr()
                for i in range(AP_num):
                    expr.addTerms(1, x_master[iter_cnt, i, j])
                master.addConstr(w * expr <= y[j])

            expr_0 = LinExpr()
            expr_1 = 0
            for i in range(AP_num):
                expr_0.addTerms(trans_delay_cloud[i], x_cloud_master[iter_cnt, i])
                expr_1 += lambda_sol[i]
                for j in range(EN_num):
                    expr_0.addTerms(trans_delay_en[i][j], x_master[iter_cnt, i, j])
            master.addConstr(expr_0 <= max_avg_delay * expr_1)

            # solve the resulted master problem
            master.optimize()

            print('Obj(master): {}'.format(master.ObjVal), end='\t | ')
            """ Update the LB """
            LB = master.ObjVal
            print('LB (iter {}): {}'.format(iter_cnt, LB), end='\t | ')

            """ Update the subproblem """
            # first, get z_sol from updated master problem
            y_sol = {}
            for key in y.keys():
                y_sol[key] = y[key].x
            y_cloud_sol = y_cloud.x

            # change the coefficient of subproblem
            for j in range(EN_num):
                constr_name_1 = 'sub_capacity_1_' + str(i)
                constr_name_2 = 'sub_capacity_2_' + str(i)
                subProblem.remove(subProblem.getConstrByName(constr_name_1))
                subProblem.remove(subProblem.getConstrByName(constr_name_2))

            constr_name_1 = 'sub_capacity_cloud_1'
            constr_name_2 = 'sub_capacity_cloud_2'
            subProblem.remove(subProblem.getConstrByName(constr_name_1))
            subProblem.remove(subProblem.getConstrByName(constr_name_2))

            # add new constraints
            # cons3 (127)
            expr = LinExpr()
            for i in range(AP_num):
                expr.addTerms(-1 * w, x_cloud[i])
            subProblem.addConstr(0 <= y_cloud_sol + expr, name='sub_capacity_cloud_1')
            subProblem.addConstr(y_cloud_sol + expr <= u_2 * M_2, name='sub_capacity_cloud_2')
            # cons4 (129)
            for j in range(EN_num):
                expr = LinExpr()
                for i in range(AP_num):
                    expr.addTerms(-1 * w, x[i, j])
                subProblem.addConstr(0 <= y_sol[j] + expr, name='sub_capacity_1_%s' % j)
                subProblem.addConstr(y_sol[j] + expr <= u_3[j] * M_3[j], name='sub_capacity_2_%s' % j)

            """ Update the lower bound """
            subProblem.optimize()

            lambda_sol = print_sub_sol(subProblem, lambda_sub, AP_num, x)
            print(lambda_sol)
            """ 
            Update the Upper bound 
            """
            if (subProblem.status == 2):
                UB = min(UB, subProblem.ObjVal + master.ObjVal - eta.x)
                # print('eta = {}'.format(eta.x))
            print('UB (iter {}): {}'.format(iter_cnt, UB), end='\t | ')
            Gap = round(100 * (UB - LB) / UB, 2)
            print('eta = {}'.format(eta.x), end='\t | ')
            print(' Gap: {} %  '.format(Gap), end='\t')

    # master.write('finalMP.lp')
    print('\n\nOptimal solution found !')
    print('Opt_Obj : {}'.format(master.ObjVal))
    print(' **  Final Gap: {} %  **  '.format(Gap))
    print('\n  **    Solution  **  ')
    print('y_cloud : {}'.format(y_cloud_sol))
    for i in y_sol.keys():
        print('edge server : {}  process task: {}'.format(i, y[i].x))

    x_res = [[] for i in range(AP_num)]
    for i in range(AP_num):
        print('i is :{}'.format(i))
        for j in range(EN_num):
            if x[i, j].x > MIN_VALUE:
                print('j is :{}'.format(j))
                print(x[i, j].x)
                x_res[i].append(trans_delay_en[i][j])
            else:
                x_res[i].append(0.0)
    return y_sol,x_res



