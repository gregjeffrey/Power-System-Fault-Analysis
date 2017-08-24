%Greg Jeffrey
%Analysis of Unbalanced Power Grids
%Term Project

    %%Reads data table and fault data (.xlsx files) and stores in matrices
    data = xlsread('data.xlsx');
    fault_data = xlsread('fault_data.xlsx');
    output_file = fopen('Output.txt', 'w');
    trans_56_type = 1;
 
    %Determines size of given system- used for dimensions of Ybus
    system_size = max(max(data(:,1)), max(data(:, 2)));
    
    %Builds Ybus for positive, negative, and zero sequence networks
    Ybus_pos = get_Ybus(data, 3, 4, 5, system_size);
    Ybus_zero = get_Ybus(data, 6, 7, 8, system_size);
    
    %Changes zero-sequence Ybus matrix to account for ungrounded Y-Y
    %transformer between bus 5 and 6, if given
    if trans_56_type == 1
        %subracts series admittance from diagonal entries
        %Note: off-diagonal admittances are negative, hence addition
        %operator
        Ybus_zero(5, 5) = Ybus_zero(5, 5) + Ybus_zero(5, 6); 
        Ybus_zero(6, 6) = Ybus_zero(6, 6) + Ybus_zero(5, 6);
        
        %Removes off-diagonal series admittance
        Ybus_zero(5, 6) = 0;
        Ybus_zero(6, 5) = 0; 
    end

    %Adds generator reactances to appropriate entries of Ybus
    Ybus_pos(1, 1) = Ybus_pos(1, 1) + 1/(1i*0.08);
    Ybus_pos(2, 2) = Ybus_pos(1, 1) + 1/(1i*0.08);
    Ybus_pos(3, 3) = Ybus_pos(1, 1) + 1/(1i*0.08);
    Ybus_pos(8, 8) = Ybus_pos(1, 1) + 1/(1i*0.08);
    
    Ybus_zero(1, 1) = Ybus_zero(1, 1) + 1/(1i*0.06);
    Ybus_zero(2, 2) = Ybus_zero(1, 1) + 1/(1i*0.06);
    Ybus_zero(3, 3) = Ybus_zero(1, 1) + 1/(1i*0.06);
    Ybus_zero(8, 8) = Ybus_zero(1, 1) + 1/(1i*0.06);
    
    %Creates Zbus from Ybus
    Zbus_pos = inv(Ybus_pos);
    Zbus_zero = inv(Ybus_zero);
    
    %Zbus_neg is identical to Zbus_pos
    Zbus_neg = Zbus_pos;
    
    %Determines fault conditions
    faulted_bus = fault_data(1);
    fault_impedance = fault_data(3);
    
    %Finds diagonal components giving Thevenin
    %impedance looking into the faulted bus
    Zthev_pos = Zbus_pos(faulted_bus, faulted_bus);
    Zthev_neg = Zbus_neg(faulted_bus, faulted_bus);
    Zthev_zero = Zbus_zero(faulted_bus, faulted_bus);

    switch fault_data(2)
        case 1
            fprintf(output_file, 'Fault_Type: 3-phase to Ground at Bus %2i', faulted_bus);
            If_pos = 1/(Zthev_pos+fault_impedance);
            If_neg = 0;
            If_zero = 0;
            
        case 2
            fprintf(output_file, 'Fault Type: Phase A to Ground at Bus %2i', faulted_bus);
            %Solves for If by combining sequence networks for SLG fault
            If_pos = 1/(Zthev_pos + Zthev_neg + Zthev_zero + 3*fault_impedance);
            %All sequence fault currents are identical to If_pos
            If_neg = If_pos;
            If_zero = If_pos;

        case 3
            fprintf(output_file, 'Fault Type: Phase B to C to Ground at Bus %2i', faulted_bus);
            %Solves for If combining sequence networks for DLG fault
            If_pos = 1/(Zthev_pos + ((Zthev_neg*(Zthev_zero+3*fault_impedance))/(Zthev_neg+Zthev_zero+3*fault_impedance)));
            If_neg = -1*If_pos*((Zthev_zero+3*fault_impedance)/(Zthev_neg+Zthev_zero+3*fault_impedance));
            If_zero = -1*If_pos*(Zthev_neg/(Zthev_neg+Zthev_zero+3*fault_impedance));

        case 4
            %Solves for If combining sequence networks for L-L fault
            fprintf(output_file, 'Fault Type: Phase B to C, Ungrounded at Bus %2i', faulted_bus);
            If_pos = 1/(Zthev_pos+Zthev_neg+fault_impedance);
            If_neg = -1*If_pos;
            If_zero = 0;
          
    end
    
    %Initializes A matrix for symmetrical components
    alpha = exp(1i*2*pi/3);
    A = [1, 1, 1; 1, alpha^2, alpha; 1, alpha, alpha^2];
    
    %Solves for fault currents in each phase
    If_3ph = A*[If_zero; If_pos; If_neg];
    If_mag = abs(If_3ph);
    If_ang = rad2deg(angle(If_3ph));
    
    %Matrix including zero, pos, and neg sequence fault currents at each
    %bus; only nonzero value is at faulted bus 
    current_mtrx = zeros(system_size, 3);
    
    %Assigns values for each sequence of If at faulted bus
    current_mtrx(faulted_bus, 1) = If_zero;
    current_mtrx(faulted_bus, 2) = If_pos;
    current_mtrx(faulted_bus, 3) = If_neg;


    for i = 1:3
        if If_mag(i) < 1e-06;
            If_mag(i) = 0;
            If_ang(i) = 0;
        end
    end

    %Creates Vbus (sequence) matrix
    Vbus = zeros(system_size, 3);
    Vbus(:, 1) = -1*Zbus_zero * current_mtrx(:, 1);
    Vbus(:, 2) = 1 - Zbus_pos * current_mtrx(:, 2); %Pre-fault bus voltages are nominal (1) in positive sequence
    Vbus(:, 3) = -1*Zbus_neg * current_mtrx(:, 3);
    
    %Creates 3-phase Vbus matrix 
    V_3ph = zeros(system_size, 3);
    for i = 1:system_size
        V_3ph(i,:) = A*Vbus(i,:).';
    end
    
    V_mag = abs(V_3ph);
    V_ang = rad2deg(angle(V_3ph));

    %Writing to Output
    fprintf(output_file, '\nFault Current');
    fprintf(output_file, '\nPhase A, Phase B, Phase C');
    formatspec = ('\n%5.3f,%7.2f,%5.3f,%7.2f,%5.3f,%7.2f'); 
    
    fprintf(output_file, formatspec, If_mag(1), If_ang(1), If_mag(2), If_ang(2), If_mag(3), If_ang(3));
    
      
    fprintf(output_file, '\nBus Voltages');
    fprintf(output_file, '\nBus,PhaseA,PhaseB,PhaseC\n');
   
    for i = 1:system_size
        formatspec = ('%3i,%5.3f,%7.2f,%5.3f,%7.2f,%5.3f,%7.2f\n');
        fprintf(output_file, formatspec, i, V_mag(i, 1), V_ang(i, 1), V_mag(i, 2), V_ang(i, 2), V_mag(i, 3), V_ang(i, 3));
    
    end
    
    
    
    
    
    
    
   
            
            
            
  
    
    
    
    
    
    
    
        
        
        
        
        
        
        
        
        
        
        
        
      
     













