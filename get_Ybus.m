%%
%Function get_Ybus
%Creates admittance matrix given dataset of resistances, reactances, and
%susceptances. 
%Inputs:
%data: matrix containing the given data
%R: Number of the column in 'data' containing Resistance
%X: Number of the column in 'data' containing Reactance
%B: Number of the column in 'data' containing Susceptance
%system_size: Number of buses in the system

function Ybus = get_Ybus(data, R, X, B, system_size)
    Ybus = zeros(system_size, system_size);
    i=1;

    while(data(i, 1) ~= 0)

        to = data(i, 1);
        from = data(i, 2);

        %Adds series + shunt admittances to diagonal component for TO bus
        Ybus(to, to) = Ybus(to, to) + 1/(data(i, R) + 1i*data(i, X)) + 1i*0.5*data(i, B); 

        %Adds series + shunt admittances to diagonal component for FROM bus
        Ybus(from, from) = Ybus(from, from) + 1/(data(i, R) + 1i*data(i, X)) + 1i*0.5*data(i, B);

        %Creates mutual admittance entries 
        Ybus(to, from) = -1/(data(i, R) + 1i*data(i, X));
        Ybus(from, to) = Ybus(to, from);

        i=i+1;    
    end  
     
end