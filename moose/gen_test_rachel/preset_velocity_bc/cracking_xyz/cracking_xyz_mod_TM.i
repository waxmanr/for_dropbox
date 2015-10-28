#
# Test to exercise the exponential stress release
#
# First x, then y, then z directions crack
#

[GlobalParams]
  order = FIRST
  family = LAGRANGE
[]

[Mesh]
  file = cracking_test.e
  displacements = 'disp_x disp_y disp_z'
[]

[Variables]

  [./disp_x]
  [../]

  [./disp_y]
  [../]

  [./disp_z]
  [../]

[]

[AuxVariables]
  [./crack_1]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./crack_2]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./crack_3]
    order = CONSTANT
    family = MONOMIAL
  [../]

  [./strain_xx]
    order = CONSTANT
    family = MONOMIAL
  [../]

  [./strain_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]

  [./strain_zz]
    order = CONSTANT
    family = MONOMIAL
  [../]

  [./stress_xx]
    order = CONSTANT
    family = MONOMIAL
  [../]

  [./stress_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]

  [./stress_zz]
    order = CONSTANT
    family = MONOMIAL
  [../]

  [./stress_xy]
    order = CONSTANT
    family = MONOMIAL
  [../]

  [./stress_yz]
    order = CONSTANT
    family = MONOMIAL
  [../]

  [./stress_zx]
    order = CONSTANT
    family = MONOMIAL
  [../]

[]

[Functions]
  [./displx]
    type = PiecewiseLinear
#   x = '0 1'
#   y = '0 .0035'
    x = '0 1'
    y = '0 0.00175'
  [../]
  [./velocity_y]
    type = ParsedFunction
    value = 'if(t < 2, 0.00175, 0)'
  [../]
  [./velocity_z]
    type = ParsedFunction
    value = 0.00175
  [../]
[]

[TensorMechanics]
  [./tensor] #changed from SM
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
  [../]
[]


[AuxKernels]
  #removed MaterialTensorAux kernels and replaced with RankTwoAux
  #need to figure out equiv to MaterialVectorAux and crack_flags in TM
  [./crack_1]
    type = MaterialVectorAux
    variable = crack_1
    vector = crack_flags #equiv in TM? don't know if there is
    index = 0
  [../]
  [./crack_2]
    type = MaterialVectorAux
    variable = crack_2
    vector = crack_flags #equiv in TM?
    index = 1
  [../]
  [./crack_3]
    type = MaterialVectorAux
    variable = crack_3
    vector = crack_flags #equiv in TM?
    index = 2
  [../]
  [./stress_xx]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_xx
    index_j = 0
    index_i = 0
  [../]
  [./stress_xy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_xy
    index_j = 1
    index_i = 0
  [../]
  [./stress_yy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_yy
    index_j = 1
    index_i = 1
  [../]
  [./stress_zz]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_zz
    index_j = 2
    index_i = 2
  [../]
  [./stress_zx]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_zx
    index_j = 0
    index_i = 2
  [../]
  [./stress_yz]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_yz
    index_j = 2
    index_i = 1
  [../]

  [./strain_xx]
    type = RankTwoAux
    rank_two_tensor = strain #called total strain?
    variable = strain_xx
    index_j = 0
    index_i = 0
  [../]
  [./strain_yy]
    type = RankTwoAux
    rank_two_tensor = strain #called total strain?
    variable = strain_yy
    index_j = 1
    index_i = 1
  [../]
  [./strain_zz]
    type = RankTwoAux
    rank_two_tensor = strain #called total strain?
    variable = strain_zz
    index_j = 2
    index_i = 2
  [../]
[]


[BCs]
  [./fix_x]
    type = PresetBC
    variable = disp_x
    boundary = 1
    value = 0.0
  [../]
  [./move_x]
    type = FunctionPresetBC
    variable = disp_x
    boundary = 4
    function = displx
  [../]

  [./fix_y]
    type = PresetBC
    variable = disp_y
    boundary = 2
    value = 0.0
  [../]
  [./move_y]
    type = PresetVelocity
    variable = disp_y
    boundary = 5
    function = velocity_y
#    time_periods = 'p2 p3'
  [../]

  [./fix_z]
    type = PresetBC
    variable = disp_z
    boundary = 3
    value = 0.0
  [../]
  [./move_z]
    type = PresetVelocity
    variable = disp_z
    boundary = 6
    function = velocity_z
#    time_periods = 'p3'
  [../]
[]

[Materials]
  [./fred]
    type = Elastic
    block = 1
    youngs_modulus = 186.5e9
    poissons_ratio = .316
    cracking_stress = 119.3e6
    cracking_release = exponential

    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
    formulation = linear
  [../]
[]

#[Preconditioning]
#  [./SMP]
#    type = SMP
#    full = true
#  []
#[]

[Executioner]
  type = Transient

  #Preconditioned JFNK (default)
  solve_type = 'PJFNK'



  petsc_options_iname = '-ksp_gmres_restart -pc_type'
  petsc_options_value = '101                lu'


  line_search = 'none'


  l_max_its = 100
  l_tol = 1e-6

  nl_max_its = 100
  nl_abs_tol = 1e-8
  #nl_rel_tol = 1e-3
  nl_rel_tol = 1e-6

  start_time = 0.0
  end_time = 3.0
#  dt = 0.005
  dt = 0.01

  [./TimePeriods]
    [./p1]
      start = 0.0
      inactive_kernels = ''
      inactive_bcs = 'move_y move_z'
    [../]

    [./p2]
      start = 1.0
      inactive_kernels = ''
      inactive_bcs = 'move_z'
    [../]

    [./p3]
      start = 2.0
      inactive_kernels = ''
      inactive_bcs = ''
    [../]
  [../]
[]

[Outputs]
  output_initial = true
  exodus = true
  print_linear_residuals = true
  print_perf_log = true
[]
