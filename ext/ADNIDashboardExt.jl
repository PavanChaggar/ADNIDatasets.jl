module ADNIDashboardExt

using ADNIDatasets
using Connectomes
using Makie
using Colors, ColorSchemes
# function ADNIDatasets.data_dashboard()
#     println("test")
# end

function get_cortex()
    parc = Parcellation(Connectomes.connectome_path())
    cortex = filter(x -> get_lobe(x) != "subcortex", parc)

    return cortex
end
get_right_cortex(cortex::Parcellation) =  filter(x -> x.Hemisphere == "right", cortex)

function normalise!(data, lower, upper)
    for i in 1:size(data, 1)
        lower_mask = data[i,:] .< lower[i]
        data[i, lower_mask] .= lower[i]
        upper_mask = data[i,:] .> upper[i]
        data[i, upper_mask] .= upper[i]
    end
end

function ADNIDatasets.data_dashboard(data::ADNIDataset, u0, ui; cmap=ColorSchemes.viridis, show_mtl_threshold = true, mtl_threshold=1.375)
    
    right_cortical_nodes = get_node_id.(get_right_cortex(get_cortex()))
    right_cortical_nodes_labels = get_label.(get_right_cortex(get_cortex()))

    n_subjects = length(data)
    
    max_time = maximum(reduce(vcat, get_times.(data)))
    
    data_all = calc_suvr.(data)
    [normalise!(data_all[i], u0, ui) for i in 1:n_subjects]
    scaleddata = [(data_all[i] .- u0) ./ (ui .- u0) for i in 1:n_subjects]
    alltimes = get_times.(data)

    p1 = Vector{Mesh}(undef, 36)
    p2 = Vector{Mesh}(undef, 36)

    f = Figure(size=(1200,600))
    ax = Axis3(f[1,1], aspect = :data, azimuth = 0.0pi, elevation=0.0pi)
    hidedecorations!(ax)
    hidespines!(ax)
    
    p1 .= plot_roi!(right_cortical_nodes, scaleddata[1][:,1], cmap)

    ax = Axis3(f[1,2], aspect = :data, azimuth = 1.0pi, elevation=0.0pi)
    hidedecorations!(ax)
    hidespines!(ax)

    p2 .= plot_roi!(right_cortical_nodes, scaleddata[1][:,1], cmap)

    Colorbar(f[2, 1:2], limits = (0, 1), colormap = cmap,
        vertical = false, label = "SUVR", labelsize=20, flipaxis=false,
        ticksize=18, ticklabelsize=20, labelpadding=3)
    f

    sg = SliderGrid(f[3, 1:3],
        (label = "Subject",
        range = 1:1:n_subjects,
        startvalue = 1,
        format = "{:1}"
        ),
        (label = "Time",
        range = 1:1:5,
        startvalue = 1,
        format = "{:1}"
        ),
        (label = "Node",
        range = 1:1:length(right_cortical_nodes),
        startvalue = 1,
        format = "{:1}"
        )
    )

    ax = Axis(f[1:2,3],
            xautolimitmargin = (0, 0), xgridcolor = (:grey, 0.5), xgridwidth = 1.0,
            xticklabelsize = 20, xticks = LinearTicks(6), xticksize=18,
            xlabel="Time / years", xlabelsize = 20, xminorticksvisible = true,
            xminorgridvisible = true,
            yautolimitmargin = (0, 0), ygridcolor = (:grey, 0.5), ygridwidth = 1,
            yticklabelsize = 20, yticks = LinearTicks(6), yticksize=18,
            ylabel="b.c. SUVR", ylabelsize = 20, yminorticksvisible = true,
            yminorgridvisible = true,
    )
    ylims!(ax, minimum(u0)-0.05, maximum(ui)+0.05)
    xlims!(ax, 0.0, max_time)
    x = Observable(0.0)
    vlines!(ax, x, color=(:red, 0.5), linewidth=5)
    if show_mtl_threshold
        hlines!(ax, mtl_threshold, color=(:black, 0.5), linewidth=5, linestyle=:dash)
    end 
    onany(sg.sliders[1].value, sg.sliders[2].value) do val, t
        for (i, j) in enumerate(right_cortical_nodes)
            w =  scaleddata[val][i,t]
            p1[i].color[] = get(cmap,w)
            p2[i].color[] = get(cmap,w)
        end
        x[] = alltimes[val][t]
    end

    point = lift(sg.sliders[1].value, sg.sliders[3].value) do x, y
        Point2f.(alltimes[x], data_all[x][right_cortical_nodes[y],:])
    end

    title = lift(sg.sliders[3].value) do i
        ax.title[] = right_cortical_nodes_labels[i]
    end

   scatter!(point, markersize=10, color=:red)

    wait(display(f))
end

end