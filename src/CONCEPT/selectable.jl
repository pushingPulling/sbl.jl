#=
selectable:
- Julia version: 
- Author: Dan
- Date: 2021-06-28
=#
abstract type Selectable end

function select(x::Selectable)
    x.selected_ = true
end

function deselect(x::Selectable)
    x.selected_ = false
end

function isSelected(x::Selectable)
    return x.selected_
end

