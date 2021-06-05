<?php

$finder = PhpCsFixer\Finder::create()
  ->exclude('var')
  ->exclude('vendor')
  ->exclude('assets')
  ->exclude('docker')
  ->in(__DIR__)
  ->name('*.php')
  ->notName('*.twig.php')
;

return (new PhpCsFixer\Config())
    ->setRules([
      '@Symfony' => true,
      '@PSR2' => true,
      'final_class' => true,
      'static_lambda' => true,
      'linebreak_after_opening_tag' => true,
      'blank_line_after_opening_tag' => true,
      'declare_strict_types' => true,
      'array_syntax' => ['syntax' => 'short'],
      'no_unused_imports' => true,
      'native_function_invocation' => true,
      'is_null' => true,
      'list_syntax' => [
        'syntax' => 'short',
      ],
      'lowercase_cast' => true,
      'lowercase_static_reference' => true,
      'mb_str_functions' => true,
      'modernize_types_casting' => true,
      'native_constant_invocation' => true,
      'native_function_casing' => true,
      'new_with_braces' => true,
      'blank_line_before_statement' => [
        'statements' => ['declare',],
      ],
      'return_type_declaration' => [
        'space_before' => 'none',
      ],
    ])
    ->setFinder($finder)
;
