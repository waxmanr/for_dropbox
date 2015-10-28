#
# Pressure Test -- explanatoin possibly not valid; this was moved from SolidMechs to
# TensorMechs for test purposes
#
# This test is taken from the Abaqus verification manual:
#   "1.3.4 Axisymmetric solid elements"
#
# The two lower nodes are not allowed to translate in the z direction.
# Step 1:
#   Pressure of 1000 is applied on each face.
# Step 2:
#   Step 1 load plus a pressure on the vertical faces that varies from
#   0 to 1000 from top to bottom.
#
# Solution:
# Step 1:
#    Stress xx, yy, zz = -1000
#    Stress xy = 0
# Step 2:
#    Stress xx, zz = -1500
#    Stress yy = -1000
#    Stress xy = 0

#[GlobalParams]
#  disp_x = disp_x
#  disp_y = disp_y
#[] replaced with below

[GlobalParams]
  displacements = 'disp_r disp_z'
[]

[Problem]
  coord_type = RZ
[]

[Mesh]#Comment
  file = pressure_rz_test.e
[] # Mesh

[Functions]
  [./constant]
    type = PiecewiseLinear
    x = '0. 1. 2.'
    y = '0. 1. 1.'
    scale_factor = 1e3
  [../]
  [./vary]
    type = ParsedFunction
    value = 'if(t <= 1, 1000 , 1000+1000*(1-y))'
  [../]
[] # Functions

[Variables]
#changed from disp_x & disp_y
  [./disp_r]
    order = FIRST
    family = LAGRANGE
  [../]
  [./disp_z]
    order = FIRST
    family = LAGRANGE
  [../]
[] # Variables

[AuxVariables]
#removed all xy stresses
[./stress_theta]
  order = CONSTANT
  family = MONOMIAL
[../]
[] # AuxVariables

[Kernels]
  [./AxisymmetricRZ]
    use_displaced_mesh = true
  [../]
[] # TensorMechanics to replace SolidMechanics (Axis... action calls TM)

[AuxKernels]
  [./stress_theta]
    type = RankTwoAux #changed from MaterialTensorAux
    rank_two_tensor = stress
    index_i = 2
    index_j = 2
    variable = stress_theta
    execute_on = timestep_end
  [../]
[]
[] # AuxKernels

[BCs]
  [./no_y]
    type = PresetBC #changed from DirichletBC
    variable = 'disp_z disp_r'
    boundary = 3
    value = 0.0
  [../]
  [./Pressure1]
    type = PressureTM
    boundary = '3 4'
    variable = disp_r
    component = 0
    function = constant
  [../]
  [./Pressure2]
    type = PressureTM
    boundary = '1 2'
    variable = disp_z
    component = 1
    function = vary
    [../]
  [../]
[] # BCs

[Materials]
#removed elastic material model from solidmechs
  [./elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 1e10
    poissons_ratio = 0.345
    block = 1
  [../]
  [./small_strain_arz]
    type = ComputeAxisymmetricRZFiniteStrain
#    thermal_expansion_coeff = 0
    block = 1
  [../]
  [./_elastic_strain]
    type = ComputeFiniteStrainElasticStress
    block = 1
  [../]
[] # Materials

[Executioner]

  type = Transient

  #Preconditioned JFNK (default)
  solve_type = 'PJFNK'

  nl_abs_tol = 1e-10
  nl_rel_tol = 1e-12

  l_max_its = 20

  start_time = 0.0
  dt = 1.0
  num_steps = 2
  end_time = 2.0
[] # Executioner

[Outputs]
  output_initial = true
  print_linear_residuals = true
  print_perf_log = true
  [./out]
    type = Exodus
    elemental_as_nodal = true
  [../]
[] # Outputs
