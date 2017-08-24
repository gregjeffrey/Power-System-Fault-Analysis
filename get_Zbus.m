function Ybus = get_Ybus(data, R, X, B)
    Ybus = zeros(14, 14);
    i=1;

    while(data(i, 1) ~= 0)

        to = data(i, 1);
        from = data(i, 2);

        %Adds series + shunt admittances to diagonal component for TO bus
        Ybus(to, to) = Ybus(to, to) + 1/(data(i, R) + j*data(i, X)) + j*0.5*data(i, B); 

        %Adds series + shunt admittances to diagonal component for FROM bus
        Ybus(from, from) = Ybus(from, from) + 1/(data(i, R) + j*data(i, X)) + j*0.5*data(i, B);

        %Creates mutual admittance entries 
        Ybus(to, from) = -1/(data(i, R) + j*data(i, X));
        Ybus(from, to) = Ybus(to, from);

        i=i+1;    
    end  
    
    %Adds generator reactances
    
    
     
end