module TemplateHelper
  def render_partial partial, locals = {}
    partial_binding = binding.dup
    set_locals locals, partial_binding

    template = get_template_for partial
    process_erb(template, partial_binding)
  end

  def set_locals locals, local_binding
    locals.each do |var, val|
      local_binding.local_variable_set var, val
    end
  end

  def get_template_for partial
    filename = "_#{partial}.rb.erb"
    File.read File.join(template_dir, filename)
  end

  def template_dir
    @template_dir ||= File.expand_path "../templates", __FILE__
  end

  if RUBY_VERSION >= "2.6"
    def process_erb template, erb_binding
      ERB.new(template, trim_mode: "-").result(erb_binding)
    end
  else
    def process_erb template, erb_binding
      ERB.new(template, nil, "-").result(erb_binding)
    end
  end
end
